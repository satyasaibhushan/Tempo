import Link from "next/link";
import { ArrowLeft, Mail, TimerReset } from "lucide-react";

export function LegalPage({
  eyebrow,
  title,
  introduction,
  children,
}: {
  eyebrow: string;
  title: string;
  introduction: string;
  children: React.ReactNode;
}) {
  return (
    <main className="min-h-screen bg-[var(--background)] px-4 py-4 text-[var(--terra-pine)] md:px-7 md:py-7">
      <article className="surface-panel mx-auto min-h-[calc(100vh-2rem)] max-w-6xl overflow-hidden md:min-h-[calc(100vh-3.5rem)]">
        <header className="flex items-center justify-between border-b border-[var(--border)] px-5 py-4 md:px-8">
          <Link href="/" className="flex items-center gap-3">
            <span className="grid size-10 place-items-center rounded-xl bg-[var(--terra-clay)] text-[#2b160e]">
              <TimerReset className="size-5" />
            </span>
            <span>
              <span className="block text-lg font-bold tracking-[-0.02em]">
                Tempo
              </span>
              <span className="block text-[9px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Personal timekeeper
              </span>
            </span>
          </Link>
          <Link
            href="/"
            className="flex items-center gap-2 text-xs font-semibold text-[var(--terra-sage)] transition hover:text-[var(--terra-pine)]"
          >
            <ArrowLeft className="size-3.5" />
            Back to Tempo
          </Link>
        </header>

        <div className="grid lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.4fr)]">
          <aside className="border-b border-[var(--border)] p-7 md:p-12 lg:min-h-[720px] lg:border-r lg:border-b-0">
            <p className="page-kicker">{eyebrow}</p>
            <h1 className="mt-8 max-w-md font-serif text-5xl leading-[0.94] tracking-[-0.025em] md:text-7xl">
              {title}
            </h1>
            <p className="mt-8 max-w-md text-sm leading-7 text-[var(--terra-sage)] md:text-base">
              {introduction}
            </p>
            <a
              href="mailto:satyasaibhushan@gmail.com"
              className="mt-10 inline-flex items-center gap-2 rounded-full border border-[var(--border)] px-4 py-2.5 text-xs font-semibold transition hover:bg-[var(--secondary)]"
            >
              <Mail className="size-3.5" />
              satyasaibhushan@gmail.com
            </a>
          </aside>

          <div className="grid gap-10 p-7 md:p-12 [&_h2]:font-serif [&_h2]:text-3xl [&_h2]:tracking-[-0.02em] [&_p]:text-sm [&_p]:leading-7 [&_p]:text-[var(--terra-sage)] [&_ul]:grid [&_ul]:gap-2 [&_ul]:pl-5 [&_li]:list-disc [&_li]:text-sm [&_li]:leading-6 [&_li]:text-[var(--terra-sage)]">
            {children}
          </div>
        </div>

        <footer className="flex flex-col gap-2 border-t border-[var(--border)] px-5 py-4 text-[10px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)] md:flex-row md:items-center md:justify-between md:px-8">
          <span>Tempo / Sai Bhushan</span>
          <span>Last updated 11 August 2026</span>
        </footer>
      </article>
    </main>
  );
}
