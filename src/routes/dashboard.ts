import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();

/**
 * GET /dashboard/kpis
 * Récupérer les KPIs principaux
 */
router.get('/kpis', authenticate, authorize('admin'), async (req, res) => {
  try {
    // KPIs mockés
    const kpis = {
      totalEtablissements: 0,
      totalDiffusions: 0,
      musiquesUnique: 0,
      artistesUnique: 0,
      couvertureGeographique: {
        villes: 0,
        regions: 0,
      },
      periode: {
        startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        endDate: new Date().toISOString(),
      },
    };

    res.json({
      success: true,
      data: kpis,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /dashboard/carte
 * Données pour la carte géographique
 */
router.get('/carte', authenticate, async (req, res) => {
  try {
    const statut = req.query.statut as string;
    const ville = req.query.ville as string;

    // Mock: données géographiques
    const mapData = {
      etablissements: [],
      total: 0,
    };

    res.json({
      success: true,
      data: mapData,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /dashboard/top-musiques
 * Top des musiques les plus diffusées
 */
router.get('/top-musiques', authenticate, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const startDate = req.query.startDate as string;
    const endDate = req.query.endDate as string;

    // Mock: top musiques
    const topMusiques: any[] = [];

    res.json({
      success: true,
      data: {
        classement: topMusiques,
        periode: { startDate, endDate },
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /dashboard/top-artistes
 * Top des artistes les plus diffusés
 */
router.get('/top-artistes', authenticate, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const startDate = req.query.startDate as string;
    const endDate = req.query.endDate as string;

    // Mock: top artistes
    const topArtistes: any[] = [];

    res.json({
      success: true,
      data: {
        classement: topArtistes,
        periode: { startDate, endDate },
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * GET /dashboard/evolution
 * Évolution temporelle des diffusions
 */
router.get('/evolution', authenticate, async (req, res) => {
  try {
    const startDate = req.query.startDate as string;
    const endDate = req.query.endDate as string;
    const granularite = req.query.granularite as string || 'jour';

    // Mock: évolution
    const evolution = {
      evolution: [],
      periode: { startDate, endDate },
    };

    res.json({
      success: true,
      data: evolution,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

export default router;
