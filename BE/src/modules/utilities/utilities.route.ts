import { Router } from 'express';
import {
  getFloodPoints,
  getWeatherAqi,
  getDepartmentsDirectory,
  getSummary,
} from './utilities.controller';

const utilityRouter = Router();

utilityRouter.get('/flood-points', getFloodPoints);
utilityRouter.get('/weather-aqi', getWeatherAqi);
utilityRouter.get('/departments', getDepartmentsDirectory);
utilityRouter.get('/summary', getSummary);

export default utilityRouter;
