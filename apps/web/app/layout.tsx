import type { Metadata } from "next";
import "./globals.css";

import { AppProviders } from "@/components/providers";
import { auth0 } from "@/lib/auth0";
import { demoSession } from "@/lib/demo";

export const metadata: Metadata = {
  title: "Tempo",
  description: "Personal time tracking",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const session = demoSession ?? (await auth0.getSession());

  return (
    <html lang="en" className="font-sans">
      <body className="min-h-screen">
        <AppProviders user={session?.user}>{children}</AppProviders>
      </body>
    </html>
  );
}
