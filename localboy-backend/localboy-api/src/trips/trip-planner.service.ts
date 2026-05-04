import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Poi } from '../entities/poi.entity';

export interface TripPlan {
    stops: PlannedStop[];
    totalDistanceKm: number;
    estimatedDurationMinutes: number;
}

interface PlannedStop {
    poi: Poi;
    order: number;
    estimatedArrival: string;
    durationMinutes: number;
    distanceFromPrev: number;
}

@Injectable()
export class TripPlannerService {
    private readonly logger = new Logger(TripPlannerService.name);
    private readonly geminiApiKey = process.env.GEMINI_API_KEY;

    constructor(
        @InjectRepository(Poi)
        private poisRepository: Repository<Poi>,
    ) { }

    /**
     * Plan an optimized trip route using AI (with algorithmic fallback).
     */
    async planTrip(
        startLat: number,
        startLng: number,
        tripType: 'half_day' | 'full_day',
        startTime: string,
        preferences?: string[],
    ): Promise<TripPlan> {
        // Fetch available POIs
        const allPois = await this.poisRepository.find({
            where: { is_active: true },
        });

        if (allPois.length === 0) {
            return { stops: [], totalDistanceKm: 0, estimatedDurationMinutes: 0 };
        }

        // Add distance from start to each POI
        const poisWithDistance = allPois.map((poi) => ({
            poi,
            distance: this.haversineDistance(startLat, startLng, Number(poi.lat), Number(poi.lng)),
        }));

        // Try AI-powered planning first
        if (this.geminiApiKey) {
            try {
                const aiPlan = await this.planWithAI(
                    poisWithDistance,
                    startLat,
                    startLng,
                    tripType,
                    startTime,
                    preferences,
                );
                if (aiPlan) return aiPlan;
            } catch (e) {
                this.logger.warn('AI planning failed, using algorithm fallback');
            }
        }

        // Algorithmic fallback
        return this.planWithAlgorithm(
            poisWithDistance,
            startLat,
            startLng,
            tripType,
            startTime,
        );
    }

    /**
     * AI-powered trip planning using Google Gemini
     */
    private async planWithAI(
        poisWithDistance: { poi: Poi; distance: number }[],
        startLat: number,
        startLng: number,
        tripType: 'half_day' | 'full_day',
        startTime: string,
        preferences?: string[],
    ): Promise<TripPlan | null> {
        const { GoogleGenerativeAI } = await import('@google/generative-ai');
        const genAI = new GoogleGenerativeAI(this.geminiApiKey!);
        const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

        const maxStops = tripType === 'full_day' ? 5 : 3;
        const maxHours = tripType === 'full_day' ? 8 : 4;

        const poiList = poisWithDistance
            .sort((a, b) => a.distance - b.distance)
            .slice(0, 15) // Top 15 nearest
            .map((p, i) => ({
                index: i,
                name: p.poi.name,
                category: p.poi.category,
                description: p.poi.description,
                distanceKm: Math.round(p.distance * 10) / 10,
                avgVisitMin: p.poi.avg_visit_minutes,
                popularity: p.poi.popularity_score,
                lat: Number(p.poi.lat),
                lng: Number(p.poi.lng),
            }));

        const prompt = `You are a trip planner for tourists in Goa, India. 
Plan an optimized ${tripType === 'full_day' ? 'full day (7-8 hours)' : 'half day (3-4 hours)'} trip.
Start time: ${startTime}
Start location: ${startLat}, ${startLng}
Max stops: ${maxStops}
Max duration: ${maxHours} hours
${preferences?.length ? `Tourist preferences: ${preferences.join(', ')}` : ''}

Available places:
${JSON.stringify(poiList, null, 2)}

Select the best ${maxStops} stops considering:
1. Distance efficiency (minimize total travel)
2. Popularity (prioritize higher scores)
3. Variety of categories
4. Time constraints

Respond with ONLY a JSON array of indices (from the available places list above) in the optimal visiting order. Example: [2, 0, 5]`;

        const result = await model.generateContent(prompt);
        const text = result.response.text();

        // Parse the AI response
        const match = text.match(/\[[\d,\s]+\]/);
        if (!match) return null;

        const indices: number[] = JSON.parse(match[0]);
        const selectedPois = indices
            .filter((i) => i >= 0 && i < poiList.length)
            .map((i) => poisWithDistance.find((p) => p.poi.name === poiList[i].name)!)
            .filter(Boolean);

        if (selectedPois.length === 0) return null;

        // Build the plan with timing
        return this.buildPlan(selectedPois, startLat, startLng, startTime);
    }

    /**
     * Algorithmic trip planning (greedy nearest-neighbor with popularity weighting)
     */
    private planWithAlgorithm(
        poisWithDistance: { poi: Poi; distance: number }[],
        startLat: number,
        startLng: number,
        tripType: 'half_day' | 'full_day',
        startTime: string,
    ): TripPlan {
        const maxStops = tripType === 'full_day' ? 5 : 3;
        const maxMinutes = tripType === 'full_day' ? 480 : 240;

        // Score = popularity * 2 - distance * 0.5
        const scored = poisWithDistance
            .map((p) => ({
                ...p,
                score: p.poi.popularity_score * 2 - p.distance * 0.5,
            }))
            .sort((a, b) => b.score - a.score);

        // Greedy selection with time budget
        const selected: { poi: Poi; distance: number }[] = [];
        let totalMinutes = 30; // Initial pickup buffer
        let currentLat = startLat;
        let currentLng = startLng;
        const used = new Set<string>();

        for (const candidate of scored) {
            if (selected.length >= maxStops) break;
            if (used.has(candidate.poi.id)) continue;

            const travelDist = this.haversineDistance(
                currentLat, currentLng,
                Number(candidate.poi.lat), Number(candidate.poi.lng),
            );
            const travelMinutes = (travelDist / 30) * 60; // ~30 km/h avg
            const visitMinutes = candidate.poi.avg_visit_minutes;

            if (totalMinutes + travelMinutes + visitMinutes > maxMinutes) continue;

            selected.push(candidate);
            used.add(candidate.poi.id);
            totalMinutes += travelMinutes + visitMinutes;
            currentLat = Number(candidate.poi.lat);
            currentLng = Number(candidate.poi.lng);
        }

        return this.buildPlan(selected, startLat, startLng, startTime);
    }

    /**
     * Build a TripPlan with timing from a list of selected POIs
     */
    private buildPlan(
        selected: { poi: Poi; distance: number }[],
        startLat: number,
        startLng: number,
        startTime: string,
    ): TripPlan {
        const stops: PlannedStop[] = [];
        let currentTime = startTime;
        let totalDistance = 0;
        let totalMinutes = 30; // pickup buffer
        currentTime = this.addMinutes(currentTime, 30);

        let prevLat = startLat;
        let prevLng = startLng;

        for (let i = 0; i < selected.length; i++) {
            const poi = selected[i].poi;
            const dist = this.haversineDistance(prevLat, prevLng, Number(poi.lat), Number(poi.lng));
            const travelMinutes = Math.round((dist / 30) * 60);

            currentTime = this.addMinutes(currentTime, travelMinutes);
            totalDistance += dist;
            totalMinutes += travelMinutes + poi.avg_visit_minutes;

            stops.push({
                poi,
                order: i + 1,
                estimatedArrival: currentTime,
                durationMinutes: poi.avg_visit_minutes,
                distanceFromPrev: Math.round(dist * 10) / 10,
            });

            currentTime = this.addMinutes(currentTime, poi.avg_visit_minutes);
            prevLat = Number(poi.lat);
            prevLng = Number(poi.lng);
        }

        return {
            stops,
            totalDistanceKm: Math.round(totalDistance * 10) / 10,
            estimatedDurationMinutes: totalMinutes,
        };
    }

    private haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
        const R = 6371;
        const dLat = ((lat2 - lat1) * Math.PI) / 180;
        const dLng = ((lng2 - lng1) * Math.PI) / 180;
        const a =
            Math.sin(dLat / 2) ** 2 +
            Math.cos((lat1 * Math.PI) / 180) *
            Math.cos((lat2 * Math.PI) / 180) *
            Math.sin(dLng / 2) ** 2;
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private addMinutes(timeStr: string, minutes: number): string {
        const [hours, mins] = timeStr.split(':').map(Number);
        const total = hours * 60 + mins + minutes;
        return `${String(Math.floor(total / 60) % 24).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
    }
}
