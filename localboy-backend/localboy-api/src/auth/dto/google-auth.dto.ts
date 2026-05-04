import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleAuthDto {
    @IsString()
    @IsNotEmpty()
    id_token: string; // Google ID token from Flutter's Google Sign-In
}
