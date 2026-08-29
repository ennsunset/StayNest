import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { DataSource } from 'typeorm';

describe('HealthController', () => {
  let controller: HealthController;
  let mockDataSource: Partial<DataSource>;

  beforeEach(async () => {
    mockDataSource = {
      query: jest.fn().mockResolvedValue([{ '?column?': 1 }]),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [{ provide: DataSource, useValue: mockDataSource }],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('returns ok when database is healthy', async () => {
    const result = await controller.check();
    expect(result.status).toBe('ok');
    expect(result.checks.database).toBe('connected');
  });

  it('returns degraded when database is down', async () => {
    (mockDataSource.query as jest.Mock).mockRejectedValue(new Error('ECONNREFUSED'));
    const result = await controller.check();
    expect(result.status).toBe('degraded');
    expect(result.checks.database).toBe('unreachable');
  });
});
