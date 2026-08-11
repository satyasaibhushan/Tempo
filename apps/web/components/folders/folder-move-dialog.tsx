"use client";

import { useState, useEffect, useCallback, useMemo } from "react";
import { useMutation, useQuery } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id, Doc } from "@convex/_generated/dataModel";
import { cn } from "@/lib/utils";
import { DEFAULT_FOLDER_COLOR } from "@tempo/shared";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { LoadingState } from "@/components/states";
import { FolderIcon, Home, Loader2, Check } from "lucide-react";

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

type FolderMoveDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  folder: Doc<"folders">;
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

type FolderFlat = Doc<"folders"> & { depth: number };

/** Build a flat list with depth indentation from a flat array of folders. */
function buildHierarchyList(
  folders: Doc<"folders">[],
  excludeId: Id<"folders">
): FolderFlat[] {
  // Collect descendants of the excluded folder
  const excludeIds = new Set<Id<"folders">>([excludeId]);

  // Multiple passes to collect all descendants
  let changed = true;
  while (changed) {
    changed = false;
    for (const f of folders) {
      if (
        f.parentFolderId &&
        excludeIds.has(f.parentFolderId) &&
        !excludeIds.has(f._id)
      ) {
        excludeIds.add(f._id);
        changed = true;
      }
    }
  }

  // Build parent->children map
  const childrenMap = new Map<string, Doc<"folders">[]>();
  const roots: Doc<"folders">[] = [];

  for (const f of folders) {
    if (excludeIds.has(f._id)) continue;
    if (!f.parentFolderId) {
      roots.push(f);
    } else {
      const key = f.parentFolderId as string;
      if (!childrenMap.has(key)) childrenMap.set(key, []);
      childrenMap.get(key)!.push(f);
    }
  }

  // DFS to flatten
  const result: FolderFlat[] = [];

  function walk(items: Doc<"folders">[], depth: number) {
    for (const item of items) {
      result.push({ ...item, depth });
      const kids = childrenMap.get(item._id as string);
      if (kids) walk(kids, depth + 1);
    }
  }

  walk(roots, 0);
  return result;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function FolderMoveDialog({
  open,
  onOpenChange,
  folder,
}: FolderMoveDialogProps) {
  const [selected, setSelected] = useState<Id<"folders"> | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const moveFolder = useMutation(api.folders.moveFolder);
  const allFolders = useQuery(api.folders.listAllFolders, open ? {} : "skip");

  const hierarchyList = useMemo(() => {
    if (!allFolders) return [];
    return buildHierarchyList(allFolders, folder._id);
  }, [allFolders, folder._id]);

  // Reset selection when opening
  useEffect(() => {
    if (open) {
      setSelected(folder.parentFolderId ?? null);
      setSubmitting(false);
    }
  }, [open, folder.parentFolderId]);

  const handleMove = useCallback(async () => {
    setSubmitting(true);
    try {
      await moveFolder({
        folderId: folder._id,
        newParentFolderId: selected ?? undefined,
      });
      onOpenChange(false);
    } catch {
      // Error handled by Convex
    } finally {
      setSubmitting(false);
    }
  }, [folder._id, selected, moveFolder, onOpenChange]);

  const currentParentId = folder.parentFolderId ?? null;
  const hasChanged = selected !== currentParentId;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Move folder</DialogTitle>
          <DialogDescription>
            Choose a new location for{" "}
            <span className="font-medium text-[var(--terra-pine)]">{folder.name}</span>.
          </DialogDescription>
        </DialogHeader>

        <div className="mt-3 max-h-72 overflow-y-auto rounded-2xl border border-[var(--border)] bg-[var(--muted)]/60">
          {allFolders === undefined ? (
            <LoadingState message="Loading folders..." className="py-6" />
          ) : (
            <div className="flex flex-col gap-0.5 p-1.5">
              {/* Move to root */}
              <button
                type="button"
                onClick={() => setSelected(null)}
                className={cn(
                  "flex items-center gap-2.5 rounded-xl px-3 py-2 text-left text-sm transition-colors",
                  selected === null
                    ? "bg-[var(--card)] text-[var(--terra-pine)]"
                    : "text-[var(--terra-sage)] hover:bg-[var(--card)]/60 hover:text-[var(--terra-pine)]"
                )}
              >
                <Home className="size-3.5 shrink-0" />
                <span className="flex-1 font-medium">Root level</span>
                {currentParentId === null && (
                  <span className="text-[10px] uppercase tracking-wider text-[var(--terra-sage)]">
                    Current
                  </span>
                )}
                {selected === null && (
                  <Check className="size-3.5 text-[var(--terra-moss)]" />
                )}
              </button>

              {/* Folder list */}
              {hierarchyList.map((f) => {
                const isCurrent = currentParentId === f._id;
                const isActive = selected === f._id;

                return (
                  <button
                    key={f._id}
                    type="button"
                    onClick={() => setSelected(f._id)}
                    className={cn(
                      "flex items-center gap-2.5 rounded-xl px-3 py-2 text-left text-sm transition-colors",
                      isActive
                        ? "bg-[var(--card)] text-[var(--terra-pine)]"
                        : "text-[var(--terra-sage)] hover:bg-[var(--card)]/60 hover:text-[var(--terra-pine)]"
                    )}
                    style={{ paddingLeft: `${f.depth * 16 + 12}px` }}
                  >
                    <span
                      className="size-2.5 shrink-0 rounded-full"
                      style={{
                        backgroundColor: f.color ?? DEFAULT_FOLDER_COLOR,
                      }}
                    />
                    <FolderIcon className="size-3.5 shrink-0 text-[var(--terra-sage)]" />
                    <span className="flex-1 truncate">{f.name}</span>
                    {isCurrent && (
                      <span className="text-[10px] uppercase tracking-wider text-[var(--terra-sage)]">
                        Current
                      </span>
                    )}
                    {isActive && (
                      <Check className="size-3.5 text-[var(--terra-moss)]" />
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </div>

        <DialogFooter className="mt-4">
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={submitting}
          >
            Cancel
          </Button>
          <Button
            type="button"
            onClick={handleMove}
            disabled={!hasChanged || submitting}
            className="gap-1.5"
          >
            {submitting && <Loader2 className="size-3.5 animate-spin" />}
            Move
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
