import { IsDateString, IsIn, IsNotEmpty, IsNumber, IsString } from 'class-validator';

export class CreateBookingDto {
    @IsDateString()
    @IsNotEmpty()
    trip_date: string;

    @IsString()
    @IsNotEmpty()
    start_time: string;

    @IsString()
    @IsIn(['half_day', 'full_day'])
    package_type: 'half_day' | 'full_day';

    @IsString()
    @IsNotEmpty()
    hotel_address: string;

    @IsNumber()
    hotel_lat: number;

    @IsNumber()
    hotel_lng: number;
}
