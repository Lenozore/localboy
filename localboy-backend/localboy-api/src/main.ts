import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Global API prefix
  app.setGlobalPrefix('api');

  // Serve uploaded files at /uploads
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' });

  // Enable CORS
  const corsOrigin = process.env.CORS_ORIGIN || '*';
  app.enableCors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  // Global validation pipe (validates DTOs automatically)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 Localboy API running on http://localhost:${port}/api`);
}
bootstrap();
