import { redirect } from "next/navigation";
import {
  ArrowUpRight,
  Download,
  Github,
  Radio,
  ShieldCheck,
  TimerReset,
} from "lucide-react";

import { auth0 } from "@/lib/auth0";

export default async function Home() {
  const session = await auth0.getSession();

  if (session) redirect("/dashboard");

  return (
    <main className="min-h-screen bg-[var(--background)] px-4 py-4 text-[var(--terra-pine)] md:px-7 md:py-7">
      <div className="surface-panel mx-auto flex min-h-[calc(100vh-2rem)] max-w-[1500px] flex-col md:min-h-[calc(100vh-3.5rem)]">
        <header className="flex items-center justify-between border-b border-[var(--border)] px-5 py-4 md:px-8">
          <div className="flex items-center gap-3">
            <span className="grid size-10 place-items-center rounded-xl bg-[var(--terra-clay)] text-[#2b160e]">
              <TimerReset className="size-5" />
            </span>
            <div>
              <div className="text-lg font-bold tracking-[-0.02em]">Tempo</div>
              <div className="text-[9px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Personal timekeeper
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 text-[9px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
            <span className="size-1.5 rounded-full bg-[var(--terra-moss)]" />
            System ready
          </div>
        </header>

        <div className="grid flex-1 lg:grid-cols-[minmax(0,1fr)_420px]">
          <section className="relative flex min-h-[600px] flex-col justify-center border-b border-[var(--border)] p-6 md:p-10 lg:border-r lg:border-b-0 lg:p-14">
            <div className="relative">
              <p className="page-kicker">Track the work / keep the evidence</p>
              <h1 className="mt-7 max-w-4xl font-serif text-[clamp(3rem,8vw,6rem)] font-medium leading-[0.95] tracking-[-0.02em] text-[var(--terra-pine)]">
                Time,
                <br />
                made visible.
              </h1>
              <p className="mt-9 max-w-lg text-sm leading-7 text-[var(--terra-sage)] md:text-base">
                A focused personal clock for honest sessions, clean history, and
                enough structure to find the pattern later.
              </p>
            </div>
          </section>

          <aside className="flex flex-col justify-between p-6 md:p-9">
            <div>
              <div className="flex items-center justify-between border-b border-[var(--border)] pb-4">
                <div className="flex items-center gap-2 text-[10px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                  <Radio className="size-3.5 text-[var(--terra-moss)]" />
                  Access panel
                </div>
                <span className="text-[9px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                  AUTH / 01
                </span>
              </div>
              <h2 className="mt-10 font-serif text-5xl leading-[0.9] tracking-[-0.02em] text-[var(--terra-pine)]">
                Pick up where you left off.
              </h2>
              <p className="mt-5 text-sm leading-6 text-[var(--terra-sage)]">
                Log in or create an account to keep your timers and history synced
                across web, iPhone, and Mac.
              </p>

              <div className="mt-9">
                <a
                  href="/auth/login"
                  className="signal-button flex h-14 items-center justify-between px-5 text-sm"
                >
                  Continue to Tempo
                  <ArrowUpRight className="size-4" />
                </a>

                <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] gap-3">
                  <a
                    href="https://github.com/satyasaibhushan/Time/releases/latest/download/Tempo.zip"
                    className="flex h-12 items-center justify-between rounded-xl border border-[var(--border)] bg-[var(--card)] px-4 text-xs font-semibold text-[var(--terra-pine)] transition-colors hover:bg-[var(--secondary)]"
                  >
                    Download for Mac
                    <Download className="size-4" />
                  </a>
                  <a
                    href="https://github.com/satyasaibhushan/Time"
                    target="_blank"
                    rel="noreferrer"
                    aria-label="View Tempo on GitHub"
                    className="grid size-12 place-items-center rounded-xl border border-[var(--border)] bg-[var(--card)] text-[var(--terra-pine)] transition-colors hover:bg-[var(--secondary)]"
                  >
                    <Github className="size-4" />
                  </a>
                </div>
                <p className="mt-3 text-[9px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                  Apple Silicon · Preview build
                </p>
              </div>
            </div>

            <div className="mt-12 border-t border-[var(--border)] pt-5">
              <div className="flex gap-3">
                <ShieldCheck className="mt-0.5 size-4 shrink-0 text-[var(--terra-moss)]" />
                <p className="text-[10px] leading-5 text-[var(--terra-sage)]">
                  Auth0 identity, Convex-backed data, and concurrent timers on
                  one shared clock. Built for personal use.
                </p>
              </div>
              <div className="mt-4 flex gap-4 text-[10px] font-semibold text-[var(--terra-sage)]">
                <a className="hover:text-[var(--terra-pine)] hover:underline" href="/privacy">
                  Privacy
                </a>
                <a className="hover:text-[var(--terra-pine)] hover:underline" href="/support">
                  Support
                </a>
              </div>
            </div>
          </aside>
        </div>
      </div>
    </main>
  );
}
