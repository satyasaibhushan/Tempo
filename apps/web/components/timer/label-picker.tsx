"use client";

import { useState, useMemo } from "react";
import { useQuery } from "convex/react";
import { api } from "@convex/_generated/api";
import type { Id } from "@convex/_generated/dataModel";
import { TagIcon, ChevronDown, Check } from "lucide-react";

import { cn } from "@/lib/utils";
import { LABEL_COLOR_TOKENS } from "@tempo/shared";
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

interface LabelDoc {
  _id: Id<"labels">;
  name: string;
  color: string;
}

function getLabelColor(color: string): string {
  const token = LABEL_COLOR_TOKENS.find((t) => t.id === color);
  return token?.value ?? color;
}

export function LabelPicker({
  value,
  onChange,
  inheritedLabelIds,
  className,
}: {
  value: Id<"labels">[];
  onChange: (labelIds: Id<"labels">[]) => void;
  inheritedLabelIds?: Id<"labels">[];
  className?: string;
}) {
  const [open, setOpen] = useState(false);
  const allLabels = useQuery(api.labels.listLabels, {});

  const inheritedSet = useMemo(
    () => new Set(inheritedLabelIds ?? []),
    [inheritedLabelIds],
  );

  const selectedSet = useMemo(() => new Set(value), [value]);

  const selectedLabels = useMemo(
    () =>
      (allLabels as LabelDoc[] | undefined)?.filter((l) =>
        selectedSet.has(l._id),
      ) ?? [],
    [allLabels, selectedSet],
  );

  const totalCount = value.length + (inheritedLabelIds?.length ?? 0);

  function toggleLabel(labelId: Id<"labels">) {
    if (selectedSet.has(labelId)) {
      onChange(value.filter((id) => id !== labelId));
    } else {
      onChange([...value, labelId]);
    }
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        className={cn(
          "inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-[var(--card)] px-3 py-1.5 text-sm font-medium text-[var(--terra-pine)] transition-colors hover:border-[var(--terra-moss)]",
          className,
        )}
      >
        <TagIcon className="size-3.5 text-[var(--terra-sage)]" />

        {totalCount > 0 ? (
          <span className="flex items-center gap-1.5">
            {selectedLabels.length > 0 && (
              <span className="flex items-center gap-1">
                {selectedLabels.slice(0, 2).map((label) => (
                  <span
                    key={label._id}
                    className="inline-flex items-center gap-1 rounded-full bg-[var(--muted)] px-1.5 py-0.5 text-xs text-[var(--muted-foreground)]"
                  >
                    <span
                      className="size-1.5 rounded-full"
                      style={{ backgroundColor: getLabelColor(label.color) }}
                    />
                    {label.name}
                  </span>
                ))}
                {totalCount > 2 && (
                  <span className="text-xs text-[var(--terra-sage)]">
                    +{totalCount - 2}
                  </span>
                )}
              </span>
            )}
            {selectedLabels.length === 0 && totalCount > 0 && (
              <span className="text-xs text-[var(--muted-foreground)]">
                {totalCount} inherited
              </span>
            )}
          </span>
        ) : (
          <span className="text-[var(--muted-foreground)]">Labels</span>
        )}

        <ChevronDown className="ml-auto size-3.5 text-[var(--terra-sage)]" />
      </PopoverTrigger>

      <PopoverContent className="w-64 rounded-xl p-0" align="start">
        <Command>
          <CommandInput placeholder="Search labels..." />
          <CommandList>
            <CommandEmpty>No labels found.</CommandEmpty>
            <CommandGroup>
              {(allLabels as LabelDoc[] | undefined)?.map((label) => {
                const isInherited = inheritedSet.has(label._id);
                const isSelected = selectedSet.has(label._id);

                return (
                  <CommandItem
                    key={label._id}
                    value={label.name}
                    disabled={isInherited}
                    onSelect={() => {
                      if (!isInherited) toggleLabel(label._id);
                    }}
                  >
                    <div
                      className={cn(
                        "flex size-4 shrink-0 items-center justify-center rounded border border-[var(--input)]",
                        (isSelected || isInherited) &&
                          "border-[var(--terra-moss)] bg-[var(--terra-moss)]/15",
                      )}
                    >
                      {(isSelected || isInherited) && (
                        <Check className="size-3 text-[var(--terra-moss)]" />
                      )}
                    </div>
                    <span
                      className="size-2.5 shrink-0 rounded-full"
                      style={{ backgroundColor: getLabelColor(label.color) }}
                    />
                    <span
                      className={cn(
                        "truncate",
                        isInherited && "text-[var(--terra-sage)]",
                      )}
                    >
                      {label.name}
                    </span>
                    {isInherited && (
                      <span className="ml-auto text-[10px] text-[var(--terra-sage)]">
                        inherited
                      </span>
                    )}
                  </CommandItem>
                );
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
