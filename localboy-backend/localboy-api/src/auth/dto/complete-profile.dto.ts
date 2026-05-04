import { IsNotEmpty, IsOptional, IsString, IsDateString } from 'class-validator';

export class CompleteProfileDto {
    @IsString()
    @IsNotEmpty()
    name: string;

    @IsDateString()
    @IsOptional()
    dob?: string;
}
