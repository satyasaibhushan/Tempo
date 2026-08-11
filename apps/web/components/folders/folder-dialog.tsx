"use client";

import { useState, useEffect, useCallback } from "react";
import { useMutation, useQuery } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id, Doc } from "@convex/_generated/dataModel";
import { cn } from "@/lib/utils";
import { FOLDER_COLOR_TOKENS, DEFAULT_FOLDER_COLOR } from "@tempo/shared";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import { Check, Loader2 } from "lucide-react";

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

type FolderDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
} & (
  | {
      mode: "create";
      parentFolderId?: Id<"folders">;
      folder?: never;
    }
  | {
      mode: "rename";
      folder: Doc<"folders">;
      parentFolderId?: never;
    }
);

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function FolderDialog({
  open,
  onOpenChange,
  mode,
  folder,
  parentFolderId,
}: FolderDialogProps) {
  const [name, setName] = useState("");
  const [selectedColor, setSelectedColor] = useState<string>(
    DEFAULT_FOLDER_COLOR
  );
  const [selectedParent, setSelectedParent] = useState<
    Id<"folders"> | undefined
  >(undefined);
  const [submitting, setSubmitting] = useState(false);

  const createFolder = useMutation(api.folders.createFolder);
  const renameFolder = useMutation(api.folders.renameFolder);

  // Only query folders for parent select in create mode
  const allFolders = useQuery(
    api.folders.listAllFolders,
    mode === "create" ? {} : "skip"
  );

  // Reset form when dialog opens
  useEffect(() => {
    if (open) {
      if (mode === "rename" && folder) {
        setName(folder.name);
        setSelectedColor(folder.color ?? DEFAULT_FOLDER_COLOR);
      } else {
        setName("");
        setSelectedColor(DEFAULT_FOLDER_COLOR);
        setSelectedParent(parentFolderId);
      }
      setSubmitting(false);
    }
  }, [open, mode, folder, parentFolderId]);

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      const trimmed = name.trim();
      if (!trimmed) return;

      setSubmitting(true);
      try {
        if (mode === "create") {
          await createFolder({
            name: trimmed,
            color: selectedColor,
            parentFolderId: selectedParent,
          });
        } else {
          await renameFolder({
            folderId: folder._id,
            name: trimmed,
          });
        }
        onOpenChange(false);
      } catch {
        // Convex will surface the error via toast / error boundary
      } finally {
        setSubmitting(false);
      }
    },
    [
      name,
      selectedColor,
      selectedParent,
      mode,
      folder,
      createFolder,
      renameFolder,
      onOpenChange,
    ]
  );

  const isCreate = mode === "create";
  const title = isCreate ? "New folder" : "Rename folder";
  const description = isCreate
    ? "Create a new folder to organize your time entries."
    : "Update this folder's name or color.";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={handleSubmit}>
          <DialogHeader>
            <DialogTitle>{title}</DialogTitle>
            <DialogDescription>{description}</DialogDescription>
          </DialogHeader>

          <div className="mt-4 flex flex-col gap-4">
            {/* Name input */}
            <div className="flex flex-col gap-1.5">
              <label
                htmlFor="folder-name"
                className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
              >
                Name
              </label>
              <Input
                id="folder-name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Work, Personal"
                autoFocus
                autoComplete="off"
              />
            </div>

            {/* Color picker */}
            <div className="flex flex-col gap-1.5">
              <span className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                Color
              </span>
              <div className="flex flex-wrap gap-2">
                {FOLDER_COLOR_TOKENS.map((token) => (
                  <button
                    key={token.id}
                    type="button"
                    onClick={() => setSelectedColor(token.value)}
                    className={cn(
                      "flex size-7 items-center justify-center rounded-full border-2 transition-all",
                      selectedColor === token.value
                        ? "border-[var(--terra-moss)] scale-110"
                        : "border-transparent hover:border-[var(--border)]"
                    )}
                    title={token.label}
                  >
                    <span
                      className="size-4 rounded-full"
                      style={{ backgroundColor: token.value }}
                    />
                    {selectedColor === token.value && (
                      <Check className="absolute size-2.5 text-[var(--terra-pine)]" />
                    )}
                  </button>
                ))}
              </div>
            </div>

            {/* Parent folder select (create mode only) */}
            {isCreate && (
              <div className="flex flex-col gap-1.5">
                <label className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
                  Parent folder
                </label>
                <Select
                  value={selectedParent ?? ""}
                  onValueChange={(val) =>
                    setSelectedParent(
                      val ? (val as Id<"folders">) : undefined
                    )
                  }
                >
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="None (root level)" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">None (root level)</SelectItem>
                    {allFolders?.map((f) => (
                      <SelectItem key={f._id} value={f._id}>
                        <span className="flex items-center gap-2">
                          <span
                            className="size-2 rounded-full"
                            style={{
                              backgroundColor: f.color ?? DEFAULT_FOLDER_COLOR,
                            }}
                          />
                          {f.name}
                        </span>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
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
              type="submit"
              disabled={!name.trim() || submitting}
              className="gap-1.5"
            >
              {submitting && <Loader2 className="size-3.5 animate-spin" />}
              {isCreate ? "Create" : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
