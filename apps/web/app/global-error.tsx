"use client";

import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <html lang="en">
      <body className="bg-[#f1f0e8] text-[#1c3a2b]">
        <main className="grid min-h-screen place-items-center p-6">
          <section className="w-full max-w-xl rounded-[2rem] border border-[#d5d6ca] bg-[#faf9f2] p-10 text-center shadow-sm">
            <p className="text-xs font-bold uppercase tracking-[0.14em] text-[#718173]">
              Tempo
            </p>
            <h1 className="mt-3 text-3xl font-bold tracking-tight">
              The app hit an unexpected error.
            </h1>
            <p className="mt-3 text-sm leading-6 text-[#718173]">
              Try loading it again. Existing time entries have not been changed.
            </p>
            <button
              type="button"
              onClick={reset}
              className="mt-6 rounded-full bg-[#1c3a2b] px-6 py-3 text-sm font-bold text-[#f8f7ef]"
            >
              Reload the app
            </button>
          </section>
        </main>
      </body>
    </html>
  );
}
