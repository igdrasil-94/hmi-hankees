import { Router } from 'express';
import authRoutes from './auth';
import etablissementsRoutes from './etablissements';
import diffusionsRoutes from './diffusions';
import dashboardRoutes from './dashboard';
import healthRoutes from './health';

const router = Router();

// Routes publiques
router.use('/auth', authRoutes);
router.use('/health', healthRoutes);

// Routes protégées
router.use('/etablissements', etablissementsRoutes);
router.use('/diffusions', diffusionsRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;
