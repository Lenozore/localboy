import { IsNotEmpty, IsString, IsIn } from 'class-validator';

export class SendOtpDto {
    @IsString()
    @IsNotEmpty()
    target: string; // phone number or email

    @IsString()
    @IsIn(['phone', 'email'])
    target_type: string;
}
