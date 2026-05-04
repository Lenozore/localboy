import { IsNotEmpty, IsString, IsIn, Length } from 'class-validator';

export class VerifyOtpDto {
    @IsString()
    @IsNotEmpty()
    target: string;

    @IsString()
    @IsIn(['phone', 'email'])
    target_type: string;

    @IsString()
    @IsNotEmpty()
    @Length(6, 6, { message: 'OTP must be exactly 6 digits' })
    otp: string;

    @IsString()
    @IsIn(['tourist', 'driver', 'guide', 'admin'])
    @IsNotEmpty()
    role?: string;
}
