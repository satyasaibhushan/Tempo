"use client";

import { useState, useMemo } from "react";
import { useQuery } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import { FolderIcon, InboxIcon, ChevronDown } from "lucide-react";

import { cn } from "@/lib/utils";
import { FOLDER_COLOR_TOKENS } from "@tempo/shared";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Command,
  CommandInput,
  CommandList,
  CommandEmpty,
  CommandGroup,
  CommandItem,
} from "@/components/ui/command";

interface FolderDoc {
  _id: Id<"folders">;
  name: string;
  color?: string;
  parentFolderId?: Id<"folders">;
  archived: boolean;
}

function buildHierarchy(folders: FolderDoc[]) {
  const depthMap = new Map<string, number>();
  const childrenMap = new Map<string, FolderDoc[]>();

  for (const f of folders) {
    const parentKey = f.parentFolderId ?? "__root__";
    if (!childrenMap.has(parentKey)) childrenMap.set(parentKey, []);
    childrenMap.get(parentKey)!.push(f);
  }

  const ordered: { folder: FolderDoc; depth: number }[] = [];

  function walk(parentId: string, depth: number) {
    const children = childrenMap.get(parentId) ?? [];
    for (const child of children) {
      ordered.push({ folder: child, depth });
      depthMap.set(child._id, depth);
      walk(child._id, depth + 1);
    }
  }

  walk("__root__", 0);
  return ordered;
}

function getFolderColor(color?: string): string {
  if (!color) return FOLDER_COLOR_TOKENS[0].value;
  const token = FOLDER_COLOR_TOKENS.find((t) => t.id === color);
  return token?.value ?? color;
}

export function FolderPicker({
  value,
  onChange,
  className,
}: {
  value?: Id<"folders">;
  onChange: (folderId?: Id<"folders">) => void;
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const allFolders = useQuery(api.folders.listAllFolders, {
    includeArchived: false,
  });

  const hierarchy = useMemo(
    () => (allFolders ? buildHierarchy(allFolders as FolderDoc[]) : []),
    [allFolders],
  );

  const selectedFolder = useMemo(
    () =>
      value
        ? (allFolders as FolderDoc[] | undefined)?.find((f) => f._id === value)
        : undefined,
    [allFolders, value],
  );

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        className={cn(
          "inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--card)] px-3 py-1.5 text-sm font-medium text-[var(--terra-pine)] transition-colors hover:border-[var(--terra-moss)]",
          className,
        )}
      >
        {selectedFolder ? (
          <>
            <span
              className="size-2.5 shrink-0 rounded-full"
              style={{ backgroundColor: getFolderColor(selectedFolder.color) }}
            />
            <span className="truncate">{selectedFolder.name}</span>
          </>
        ) : (
          <>
            <InboxIcon className="size-3.5 text-[var(--terra-sage)]" />
            <span className="text-[var(--muted-foreground)]">Inbox</span>
          </>
        )}
        <ChevronDown className="ml-auto size-3.5 text-[var(--terra-sage)]" />
      </PopoverTrigger>

      <PopoverContent className="w-64 rounded-xl p-0" align="start">
        <Command>
          <CommandInput placeholder="Search folders..." />
          <CommandList>
            <CommandEmpty>No folders found.</CommandEmpty>
            <CommandGroup>
              <CommandItem
                value="__inbox__"
                data-checked={!value ? "true" : undefined}
                onSelect={() => {
                  onChange(undefined);
                  setOpen(false);
                }}
              >
                <InboxIcon className="size-3.5 text-[var(--terra-sage)]" />
                <span>Inbox</span>
              </CommandItem>

              {hierarchy.map(({ folder, depth }) => (
                <CommandItem
                  key={folder._id}
                  value={folder.name}
                  data-checked={value === folder._id ? "true" : undefined}
                  onSelect={() => {
                    onChange(folder._id);
                    setOpen(false);
                  }}
                  style={{ paddingLeft: `${8 + depth * 16}px` }}
                >
                  <span
                    className="size-2.5 shrink-0 rounded-full"
                    style={{
                      backgroundColor: getFolderColor(folder.color),
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
