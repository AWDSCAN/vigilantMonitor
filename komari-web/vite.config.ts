import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import Pages from "vite-plugin-pages";
import { visualizer } from "rollup-plugin-visualizer";
import { VitePWA } from "vite-plugin-pwa";

// https://vite.dev/config/
import type { UserConfig } from "vite";
import * as fs from "fs";
import * as path from "path";
import dotenv from "dotenv";

export default defineConfig(({ mode }) => {
  const buildTime = new Date().toISOString();

  // Supports configuring BASE_URL via environment variables, defaulting to the root path.
  const base: string = process.env.VITE_BASE_URL ? process.env.VITE_BASE_URL : '/';
  const baseConfig: UserConfig = {
    base: base,
    plugins: [
      react(),
      tailwindcss(),
      Pages({
        dirs: "src/pages",
        extensions: ["tsx", "jsx"],
      }),
      VitePWA({
        registerType: "autoUpdate",
        includeAssets: ["favicon.ico", "assets/pwa-icon.png"],
        manifest: {
          name: "vigilant Monitor",
          short_name: "vigilant Monitor",
          description: "A simple server monitor tool",
          theme_color: "#2563eb",
          background_color: "#ffffff",
          display: "standalone",
          scope: base,
          start_url: base,
          icons: [
            {
              src: "${base}assets/pwa-icon.png",
              sizes: "192x192",
              type: "image/png",
              purpose: "maskable any",
            },
            {
              src: "${base}assets/pwa-icon.png",
              sizes: "512x512",
              type: "image/png",
              purpose: "maskable any",
            },
          ],
        },
        workbox: {
          globPatterns: ["**/*.{js,css,html,ico,png,svg}"],
          runtimeCaching: [
            {
              urlPattern: /^https:\/\/api\./i,
              handler: "NetworkFirst",
              options: {
                cacheName: "api-cache",
                expiration: {
                  maxEntries: 10,
                  maxAgeSeconds: 60 * 60 * 24 * 365, // <== 365 days
                },
                cacheableResponse: {
                  statuses: [0, 200],
                },
              },
            },
          ],
        },
      }),
      visualizer({
        open: false,
        filename: "bundle-analysis.html",
        gzipSize: true,
        brotliSize: true,
      }),
    ],
    define: {
      __BUILD_TIME__: JSON.stringify(buildTime),
    },
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
    },
    build: {
      assetsDir: "assets",
      outDir: "dist",
      chunkSizeWarningLimit: 800,
      rollupOptions: {
        output: {
          // go embed ignore files start with '_'
          chunkFileNames: "assets/chunk-[name]-[hash].js",
          entryFileNames: "assets/entry-[name]-[hash].js",
          // Do not use manualChunks, use React.lazy() and <Suspense> instead
        }
      },
    },
  };

  if (mode === "development") {
    const envPath = path.resolve(process.cwd(), ".env.development");
    if (fs.existsSync(envPath)) {
      const envConfig = dotenv.parse(fs.readFileSync(envPath));
      for (const k in envConfig) {
        process.env[k] = envConfig[k];
      }
    }
    if (!process.env.VITE_API_TARGET) {
      process.env.VITE_API_TARGET = "https://127.0.0.1:25774";
    }

    // SSL证书路径（使用后端生成的证书）
    const sslCertPath = path.resolve(__dirname, "../vigilantMonitorServer/data/ssl/cert.pem");
    const sslKeyPath = path.resolve(__dirname, "../vigilantMonitorServer/data/ssl/key.pem");

    // 检查SSL证书是否存在
    const sslEnabled = fs.existsSync(sslCertPath) && fs.existsSync(sslKeyPath);

    baseConfig.server = {
      https: sslEnabled ? {
        cert: fs.readFileSync(sslCertPath),
        key: fs.readFileSync(sslKeyPath),
      } : undefined,
      proxy: {
        "/api": {
          target: process.env.VITE_API_TARGET,
          changeOrigin: true,
          rewriteWsOrigin: true,
          ws: true,
          secure: false, // 允许自签名证书
        },
        "/themes": {
          target: process.env.VITE_API_TARGET,
          changeOrigin: true,
          secure: false, // 允许自签名证书
        },
      },
    };

    if (sslEnabled) {
      console.log("✓ HTTPS enabled for Vite dev server");
      console.log(`  Certificate: ${sslCertPath}`);
      console.log(`  Private Key: ${sslKeyPath}`);
    } else {
      console.warn("⚠️  SSL certificates not found, running HTTP mode");
      console.warn(`  Expected cert: ${sslCertPath}`);
      console.warn(`  Expected key: ${sslKeyPath}`);
      console.warn("  Run: cd ../vigilantMonitorServer && ./vigilantMonitorServer ssl generate");
    }
  }

  return baseConfig;
});
