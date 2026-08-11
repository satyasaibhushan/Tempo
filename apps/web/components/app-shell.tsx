"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { LucideIcon } from "lucide-react";
import {
  BookOpenText,
  Download,
  FolderTree,
  Gauge,
  Github,
  LogOut,
  Settings,
  Tags,
  Timer,
} from "lucide-react";

import { cn } from "@/lib/utils";
import { useTimerController } from "@/components/timer/timer-controller";

type NavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
};

const navigation: NavItem[] = [
  { href: "/dashboard", label: "Now", icon: Gauge },
  { href: "/entries", label: "Log", icon: BookOpenText },
  { href: "/folders", label: "Folders", icon: FolderTree },
  { href: "/labels", label: "Labels", icon: Tags },
  { href: "/settings", label: "Setup", icon: Settings },
];

export function AppShell({
  children,
  user,
}: {
  children: React.ReactNode;
  user: {
    email?: string;
    imageUrl?: string;
    name: string;
  };
}) {
  const pathname = usePathname();
  const { activeTimers } = useTimerController();
  const userInitial = user.name.charAt(0).toUpperCase();
  const runningCount =
    activeTimers?.filter((timer) => timer.status === "running").length ?? 0;
  const pausedCount =
    activeTimers?.filter((timer) => timer.status === "paused").length ?? 0;

  return (
    <div className="min-h-screen">
      <div className="mx-auto flex min-h-screen w-full max-w-[1240px] flex-col lg:flex-row">
        <aside className="flex-none px-4 pt-5 lg:sticky lg:top-0 lg:h-screen lg:w-[218px] lg:px-[18px] lg:py-[26px]">
          <div className="flex h-full flex-col gap-6">
            <div className="flex items-center justify-between gap-4">
              <Link href="/dashboard" className="flex items-center gap-2.5">
                <span className="grid size-[34px] place-items-center rounded-xl bg-[var(--terra-pine)] text-[var(--terra-hero-foreground)]">
                  <Timer className="size-4" strokeWidth={2.2} />
                </span>
                <span className="text-[17px] font-bold tracking-[-0.01em]">
                  Tempo
                </span>
              </Link>

              <div
                className={cn(
                  "flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-semibold",
                  runningCount > 0
                    ? "bg-[var(--terra-amber)]/25 text-[#7d5a24]"
                    : "bg-[var(--muted)] text-[var(--terra-sage)]",
                )}
                title={
                  runningCount > 0
                    ? `${runningCount} running${pausedCount > 0 ? `, ${pausedCount} paused` : ""}`
                    : pausedCount > 0
                      ? `${pausedCount} paused`
                      : "No timers"
                }
              >
                <span
                  className={cn(
                    "size-[7px] rounded-full",
                    runningCount > 0
                      ? "animate-pulse bg-[var(--terra-amber)]"
                      : pausedCount > 0
                        ? "bg-[var(--terra-sage)]"
                        : "bg-[var(--input)]",
                  )}
                />
                {runningCount > 0
                  ? `${runningCount} live`
                  : pausedCount > 0
                    ? `${pausedCount} held`
                    : "Idle"}
              </div>
            </div>

            <nav className="flex gap-1 overflow-x-auto pb-1 lg:flex-col lg:gap-[3px] lg:overflow-visible lg:pb-0">
              {navigation.map((item) => {
                const active =
                  pathname === item.href || pathname.startsWith(`${item.href}/`);
                const Icon = item.icon;

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "flex min-w-fit items-center gap-[11px] rounded-xl px-3 py-2.5 text-[14.5px] font-medium transition-colors lg:w-full",
                      active
                        ? "bg-[var(--terra-pine)] text-[#f2f4ec]"
                        : "text-[var(--muted-foreground)] hover:bg-[var(--secondary)] hover:text-[var(--terra-pine)]",
                    )}
                  >
                    <Icon
                      className={cn("size-[18px]", !active && "opacity-80")}
                      strokeWidth={active ? 2.2 : 1.9}
                    />
                    {item.label}
                  </Link>
                );
              })}
            </nav>

            <div className="lg:mt-auto lg:flex lg:flex-col lg:gap-3">
              <div className="grid grid-cols-2 gap-1 rounded-[14px] border border-[var(--border)] bg-[var(--secondary)] p-1">
                <a
                  href="https://github.com/satyasaibhushan/Tempo/releases/latest/download/Tempo.zip"
                  className="flex h-9 items-center justify-center gap-2 whitespace-nowrap rounded-[10px] bg-[var(--card)] text-[11px] font-semibold text-[var(--terra-pine)] transition-colors hover:bg-[var(--popover)]"
                >
                  <Download className="size-3.5" />
                  Mac app
                </a>
                <a
                  href="https://github.com/satyasaibhushan/Tempo"
                  target="_blank"
                  rel="noreferrer"
                  className="flex h-9 items-center justify-center gap-2 whitespace-nowrap rounded-[10px] text-[11px] font-semibold text-[var(--terra-pine)] transition-colors hover:bg-[var(--card)]"
                >
                  <Github className="size-3.5" />
                  GitHub
                </a>
              </div>

              <div className="hidden items-center gap-2.5 lg:flex">
                {user.imageUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    alt={user.name}
                    className="size-7 rounded-full object-cover"
                    src={user.imageUrl}
                  />
                ) : (
                  <span className="grid size-7 place-items-center rounded-full bg-[var(--terra-clay)] text-xs font-bold text-white">
                    {userInitial}
                  </span>
                )}
                <span className="min-w-0 flex-1 truncate text-xs text-[var(--terra-sage)]">
                  {user.name} · personal
                </span>
                <a
                  href="/auth/logout"
                  className="grid size-7 place-items-center rounded-lg text-[var(--terra-sage)] transition-colors hover:bg-[var(--secondary)] hover:text-[var(--terra-clay)]"
                  title="Log out"
                >
                  <LogOut className="size-3.5" />
                </a>
              </div>
            </div>
          </div>
        </aside>

        <main className="min-w-0 flex-1 px-4 py-6 md:px-8 lg:px-[42px] lg:py-[26px]">
          {children}
        </main>
      </div>
    </div>
  );
}
