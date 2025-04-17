import React from 'react';
import { Container, Typography, Button, Box, Paper } from '@mui/material';
import Navbar from '../components/Navbar';

export default function Home() {
  return (
    <>
      <Navbar />
      <Container maxWidth="md">
        <Box sx={{ mt: 8, mb: 4, textAlign: 'center' }}>
          <Typography variant="h2" component="h1" gutterBottom>
            Bienvenue sur Brickify
          </Typography>
          <Typography variant="h5" component="h2" gutterBottom color="text.secondary">
            Votre assistant intelligent pour l'analyse de briques LEGO
          </Typography>
        </Box>

        <Paper elevation={3} sx={{ p: 4, mb: 4 }}>
          <Typography variant="h6" gutterBottom>
            Commencez à analyser vos briques
          </Typography>
          <Typography paragraph>
            Téléchargez une photo de vos briques LEGO et laissez notre IA les analyser pour vous.
            Obtenez des informations détaillées sur chaque pièce et des suggestions de construction.
          </Typography>
          <Button
            variant="contained"
            size="large"
            href="/analyze"
          >
            Analyser mes briques
          </Button>
        </Paper>
      </Container>
    </>
  );
} 