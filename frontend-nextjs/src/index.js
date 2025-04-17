import { Container, Typography, Box } from '@mui/material';

export default function Home() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Bienvenue sur Brickify
        </Typography>
        <Typography variant="body1">
          Votre plateforme de création de LEGO personnalisés
        </Typography>
      </Box>
    </Container>
  );
} 