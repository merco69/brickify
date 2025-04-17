import React from 'react';
import { AppBar, Toolbar, Typography, Button, Box } from '@mui/material';
import Link from 'next/link';

function Navbar() {
  return (
    <AppBar position="static">
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
          Brickify
        </Typography>
        <Box>
          <Link href="/" passHref>
            <Button color="inherit">Accueil</Button>
          </Link>
          <Link href="/analyze" passHref>
            <Button color="inherit">Analyser</Button>
          </Link>
          <Link href="/login" passHref>
            <Button color="inherit">Connexion</Button>
          </Link>
        </Box>
      </Toolbar>
    </AppBar>
  );
}

export default Navbar; 