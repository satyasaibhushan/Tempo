"use client";

import { useState, useEffect } from "react";
import { useMutation } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import { Check } from "lucide-react";
import { cn } from "@/lib/utils";
import { LABEL_COLOR_TOKENS, DEFAULT_LABEL_COLOR } from "@tempo/shared";
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

type LabelDoc = {
  _id: Id<"labels">;
  name: string;
  color: string;
};

interface LabelDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  mode: "create" | "edit";
  label?: LabelDoc;
}

export function LabelDialog({
  open,
  onOpenChange,
  mode,
  label,
}: LabelDialogProps) {
  const createLabel = useMutation(api.labels.createLabel);
  const updateLabel = useMutation(api.labels.updateLabel);

  const [name, setName] = useState("");
  const [color, setColor] = useState(DEFAULT_LABEL_COLOR);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) {
      if (mode === "edit" && label) {
        setName(label.name);
        setColor(label.color);
      } else {
        setName("");
        setColor(DEFAULT_LABEL_COLOR);
      }
    }
  }, [open, mode, label]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    const trimmed = name.trim();
    if (!trimmed) return;

    setSaving(true);
    try {
      if (mode === "create") {
        await createLabel({ name: trimmed, color });
      } else if (label) {
        await updateLabel({ labelId: label._id, name: trimmed, color });
      }
      onOpenChange(false);
    } finally {
      setSaving(false);
    }
  }

  const isValid = name.trim().length > 0;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {mode === "create" ? "Create label" : "Edit label"}
          </DialogTitle>
          <DialogDescription>
            {mode === "create"
              ? "Add a new label to your library."
              : "Update this label's name or color."}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="grid gap-5">
          {/* Name input */}
          <div className="grid gap-2">
            <label
              htmlFor="label-name"
              className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]"
            >
              Name
            </label>
            <Input
              id="label-name"
              placeholder="e.g. Deep Work"
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoFocus
              className="rounded-2xl border-transparent bg-[var(--muted)] placeholder:text-[var(--terra-sage)] focus-visible:border-[var(--terra-moss)] focus-visible:ring-0"
            />
          </div>

          {/* Color picker */}
          <div className="grid gap-2">
            <span className="text-[11px] font-semibold uppercase tracking-[0.1em] text-[var(--terra-sage)]">
              Color
            </span>
            <div className="flex flex-wrap gap-2">
              {LABEL_COLOR_TOKENS.map((token) => (
                <button
                  key={token.id}
                  type="button"
                  aria-label={token.label}
                  onClick={() => setColor(token.value)}
                  className={cn(
                    "relative flex size-8 items-center justify-center rounded-full transition-all",
                    color === token.value
                      ? "ring-2 ring-[var(--terra-moss)] ring-offset-2 ring-offset-[var(--card)]"
                      : "hover:ring-1 hover:ring-[var(--border)] hover:ring-offset-1 hover:ring-offset-[var(--card)]"
                  )}
                  style={{ backgroundColor: token.value }}
                >
                  {color === token.value && (
                    <Check className="size-4 text-[var(--terra-pine)]" strokeWidth={3} />
                  )}
                </button>
              ))}
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={!isValid || saving}
              className="signal-button"
            >
              {saving
                ? "Saving..."
                : mode === "create"
                  ? "Create label"
                  : "Save changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
