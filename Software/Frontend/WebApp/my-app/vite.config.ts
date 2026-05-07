import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const backendPort = process.env.SPRING_PORT ?? '8080'
const backendTarget =
  process.env.VITE_API_PROXY_TARGET ?? `http://localhost:${backendPort}`

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
  server: {
    proxy: {
      '/api': {
        target: backendTarget,
        changeOrigin: true,
        secure: false,
      },
    },
  },
})
