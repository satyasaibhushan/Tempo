import type { NextConfig } from "next";

import { demoBuildProblem } from "./lib/demo";

// Demo mode bypasses Auth0 (lib/demo.ts); fail the build rather than ship its switch or admin key.
const demoProblem = demoBuildProblem(process.env);
if (demoProblem) throw new Error(demoProblem);

const nextConfig: NextConfig = {
  transpilePackages: ["@tempo/shared"],
};

export default nextConfig;
