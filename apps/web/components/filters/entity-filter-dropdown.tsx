"use client";

import { useMemo, useState } from "react";
import {
  ChevronDown,
  FolderIcon,
  InboxIcon,
  Layers3,
  TagIcon,
} from "lucide-react";

import type { Doc, Id } from "@convex/_generated/dataModel";
import { FOLDER_COLOR_TOKENS, LABEL_COLOR_TOKENS } from "@tempo/shared";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";

export type FolderFilterValue = "all" | "inbox" | Id<"folders">;
export type LabelFilterValue = "all" | Id<"labels">;

const triggerClass =
  "inline-flex h-8 min-w-0 items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--card)] px-3 text-[0.8rem] font-semibold text-[var(--muted-foreground)] transition-colors hover:border-[var(--terra-moss)] focus-visible:border-[var(--terra-moss)] focus-visible:outline-none data-[active=true]:border-[var(--terra-moss)] data-[active=true]:bg-[var(--terra-moss)]/10 data-[active=true]:text-[var(--terra-moss)]";

function tokenColor(
  color: string | undefined,
  tokens: readonly { id: string; value: string }[],
): string {
  if (!color) return tokens[0].value;
  return tokens.find((token) => token.id === color)?.value ?? color;
}

function folderHierarchy(folders: Doc<"folders">[]) {
  const children = new Map<string, Doc<"folders">[]>();
  for (const folder of folders) {
    const key = folder.parentFolderId ?? "root";
    children.set(key, [...(children.get(key) ?? []), folder]);
  }

  const result: Array<{ folder: Doc<"folders">; depth: number }> = [];
  const visit = (parentId: string, depth: number) => {
    for (const folder of children.get(parentId) ?? []) {
      result.push({ folder, depth });
      visit(folder._id, depth + 1);
    }
  };
  visit("root", 0);
  return result;
}

export function FolderFilterDropdown({
  value,
  onChange,
  folders,
  align = "start",
  allLabel = "All folders",
}: {
  value: FolderFilterValue;
  onChange: (value: FolderFilterValue) => void;
  folders: Doc<"folders">[];
  align?: "start" | "center" | "end";
  allLabel?: string;
}) {
  const [open, setOpen] = useState(false);
  const hierarchy = useMemo(() => folderHierarchy(folders), [folders]);
  const selected =
    value === "all" || value === "inbox"
      ? undefined
      : folders.find((folder) => folder._id === value);

  const choose = (nextValue: FolderFilterValue) => {
    onChange(nextValue);
    setOpen(false);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        aria-label="Filter by folder"
        data-active={value !== "all"}
        className={triggerClass}
      >
        {value === "all" ? (
          <Layers3 className="size-3.5 opacity-70" />
        ) : value === "inbox" ? (
          <InboxIcon className="size-3.5" />
        ) : (
          <span
            className="size-2.5 shrink-0 rounded-full"
            style={{
              backgroundColor: tokenColor(
                selected?.color,
                FOLDER_COLOR_TOKENS,
              ),
            }}
          />
        )}
        <span className="max-w-36 truncate">
          {value === "all"
            ? allLabel
            : value === "inbox"
              ? "Inbox"
              : selected?.name ?? "Folder"}
        </span>
        <ChevronDown className="size-3.5 opacity-55" />
      </PopoverTrigger>

      <PopoverContent className="w-72 rounded-2xl p-0" align={align}>
        <Command>
          <CommandInput placeholder="Find a folder…" />
          <CommandList>
            <CommandEmpty>No folders found.</CommandEmpty>
            <CommandGroup heading="Scope">
              <CommandItem
                value="All folders"
                data-checked={value === "all" ? "true" : undefined}
                onSelect={() => choose("all")}
              >
                <Layers3 className="size-4 text-[var(--terra-sage)]" />
                <span>All folders</span>
              </CommandItem>
              <CommandItem
                value="Inbox"
                data-checked={value === "inbox" ? "true" : undefined}
                onSelect={() => choose("inbox")}
              >
                <InboxIcon className="size-4 text-[var(--terra-clay)]" />
                <span>Inbox</span>
              </CommandItem>
            </CommandGroup>
            {hierarchy.length > 0 && <CommandSeparator />}
            <CommandGroup heading="Folders">
              {hierarchy.map(({ folder, depth }) => (
                <CommandItem
                  key={folder._id}
                  value={`${folder.name} ${folder._id}`}
                  data-checked={value === folder._id ? "true" : undefined}
                  onSelect={() => choose(folder._id)}
                  style={{ paddingLeft: `${8 + depth * 14}px` }}
                >
                  <span
                    className="size-2.5 shrink-0 rounded-full"
                    style={{
                      backgroundColor: tokenColor(
                        folder.color,
                        FOLDER_COLOR_TOKENS,
                      ),
                    }}
                  />
                  <FolderIcon className="size-3.5 text-[var(--terra-sage)]" />
                  <span className="truncate">{folder.name}</span>
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}

export function LabelFilterDropdown({
  value,
  onChange,
  labels,
  align = "start",
  allLabel = "All labels",
}: {
  value: LabelFilterValue;
  onChange: (value: LabelFilterValue) => void;
  labels: Doc<"labels">[];
  align?: "start" | "center" | "end";
  allLabel?: string;
}) {
  const [open, setOpen] = useState(false);
  const selected =
    value === "all" ? undefined : labels.find((label) => label._id === value);

  const choose = (nextValue: LabelFilterValue) => {
    onChange(nextValue);
    setOpen(false);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        aria-label="Filter by label"
        data-active={value !== "all"}
        className={triggerClass}
      >
        {selected ? (
          <span
            className="size-2.5 shrink-0 rounded-full"
            style={{
              backgroundColor: tokenColor(selected.color, LABEL_COLOR_TOKENS),
            }}
          />
        ) : (
          <TagIcon className="size-3.5 opacity-70" />
        )}
        <span className="max-w-36 truncate">{selected?.name ?? allLabel}</span>
        <ChevronDown className="size-3.5 opacity-55" />
      </PopoverTrigger>

      <PopoverContent className="w-64 rounded-2xl p-0" align={align}>
        <Command>
          <CommandInput placeholder="Find a label…" />
          <CommandList>
            <CommandEmpty>No labels found.</CommandEmpty>
            <CommandGroup>
              <CommandItem
                value="All labels"
                data-checked={value === "all" ? "true" : undefined}
                onSelect={() => choose("all")}
              >
                <TagIcon className="size-4 text-[var(--terra-sage)]" />
                <span>All labels</span>
              </CommandItem>
              {labels.map((label) => (
                <CommandItem
                  key={label._id}
                  value={`${label.name} ${label._id}`}
                  data-checked={value === label._id ? "true" : undefined}
                  onSelect={() => choose(label._id)}
                >
                  <span
                    className="size-2.5 shrink-0 rounded-full"
                    style={{
                      backgroundColor: tokenColor(
                        label.color,
                        LABEL_COLOR_TOKENS,
                      ),
                    }}
                  />
                  <span className="truncate">{label.name}</span>
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
