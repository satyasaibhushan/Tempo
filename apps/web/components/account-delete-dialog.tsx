"use client";

import { useState } from "react";
import { useAction } from "convex/react";
import { AlertTriangle, Loader2 } from "lucide-react";

import { api } from "@convex/_generated/api";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

export function AccountDeleteDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const deleteAccount = useAction(api.accountDeletion.deleteCurrentAccount);
  const [confirmation, setConfirmation] = useState("");
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string>();

  function handleOpenChange(nextOpen: boolean) {
    if (deleting) return;
    onOpenChange(nextOpen);
    if (!nextOpen) {
      setConfirmation("");
      setError(undefined);
    }
  }

  async function handleDelete() {
    setDeleting(true);
    setError(undefined);
    try {
      await deleteAccount({});
      window.location.assign("/auth/logout?returnTo=/");
    } catch (caught) {
      setError(
        caught instanceof Error
          ? caught.message
          : "Tempo could not delete this account. Please try again.",
      );
      setDeleting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-md" showCloseButton={!deleting}>
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-[var(--destructive)]">
            <AlertTriangle className="size-4" />
            Permanently delete your account?
          </DialogTitle>
          <DialogDescription>
            This removes your Tempo profile, timers, entries, folders, labels,
            and sign-in identity. Nothing can be recovered afterward.
          </DialogDescription>
        </DialogHeader>

        <div className="grid gap-2">
          <label
            htmlFor="delete-account-confirmation"
            className="text-xs font-semibold text-[var(--terra-pine)]"
          >
            Type <span className="font-mono">DELETE</span> to confirm
          </label>
          <Input
            id="delete-account-confirmation"
            autoComplete="off"
            value={confirmation}
            onChange={(event) => setConfirmation(event.target.value)}
            disabled={deleting}
          />
          {error ? (
            <p className="text-xs leading-5 text-[var(--destructive)]">
              {error}
            </p>
          ) : null}
        </div>

        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => handleOpenChange(false)}
            disabled={deleting}
          >
            Keep account
          </Button>
          <Button
            type="button"
            variant="destructive"
            disabled={confirmation !== "DELETE" || deleting}
            onClick={handleDelete}
            className="rounded-full bg-[var(--destructive)] text-white hover:bg-[var(--destructive)]/90"
          >
            {deleting ? <Loader2 className="size-4 animate-spin" /> : null}
            {deleting ? "Deleting…" : "Delete account"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
