import { Injectable } from '@nestjs/common';

export interface PriceBreakdown {
    baseFare: number;
    perKmCharge: number;
    perStopCharge: number;
    subtotal: number;
    platformFee: number;
    totalTouristCharge: number;
    driverPayout: number;
    guidePayout: number;
    platformRevenue: number;
    distanceKm: number;
    stopCount: number;
}

@Injectable()
export class PricingService {
    // ─── RATE CARD ────────────────────────────────────────

    private readonly RATES = {
        half_day: {
            baseFare: 500,
            perKm: 12,
            perStop: 100,
            driverBasePay: 300,
            driverPerKm: 8,
            guidePay: 0, // Driver is the guide for half-day
        },
        full_day: {
            baseFare: 800,
            perKm: 12,
            perStop: 100,
            driverBasePay: 500,
            driverPerKm: 8,
            guidePay: 500,
        },
    };

    private readonly PLATFORM_FEE_PERCENT = 0.15; // 15%

    // ─── CALCULATE PRICE ─────────────────────────────────

    calculate(
        tripType: 'half_day' | 'full_day',
        distanceKm: number,
        stopCount: number,
    ): PriceBreakdown {
        const rates = this.RATES[tripType];

        const baseFare = rates.baseFare;
        const perKmCharge = Math.round(rates.perKm * distanceKm);
        const perStopCharge = rates.perStop * stopCount;
        const subtotal = baseFare + perKmCharge + perStopCharge;
        const platformFee = Math.round(subtotal * this.PLATFORM_FEE_PERCENT);
        const totalTouristCharge = subtotal + platformFee;

        // Driver payout: base + per-km (covers fuel)
        const driverPayout = rates.driverBasePay + Math.round(rates.driverPerKm * distanceKm);

        // Guide payout: flat rate (full day only)
        const guidePayout = rates.guidePay;

        // Platform keeps: total - driver - guide
        const platformRevenue = totalTouristCharge - driverPayout - guidePayout;

        return {
            baseFare,
            perKmCharge,
            perStopCharge,
            subtotal,
            platformFee,
            totalTouristCharge,
            driverPayout,
            guidePayout,
            platformRevenue,
            distanceKm: Math.round(distanceKm * 10) / 10,
            stopCount,
        };
    }

    /**
     * Recalculate when tourist adds/removes a stop
     */
    recalculate(
        tripType: 'half_day' | 'full_day',
        newDistanceKm: number,
        newStopCount: number,
    ): PriceBreakdown {
        return this.calculate(tripType, newDistanceKm, newStopCount);
    }
}
