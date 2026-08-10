import { v } from "convex/values";
import { paginationOptsValidator } from "convex/server";

import type { Doc } from "./_generated/dataModel";
import { mutation, query } from "./_generated/server";
import { getCurrentUserOrThrow } from "./helpers";
import { retimeActiveTimerSegments } from "./timeEntryLogic";

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/** Timer lifecycle events only need whole-second precision. */
function wholeSecondNow(): number {
  return Math.floor(Date.now() / 1_000) * 1_000;
}

/**
 * Compute the total duration in seconds from a list of segments.
 * Open segments (no endTime) are ignored — only closed segments count.
 */
function computeDurationSeconds(
  segments: Array<{ startTime: number; endTime?: number }>,
): number {
  let total = 0;

  for (const seg of segments) {
    if (seg.endTime !== undefined) {
      total += (seg.endTime - seg.startTime) / 1000;
    }
  }

  return Math.round(total);
}

// ---------------------------------------------------------------------------
// Queries
// ---------------------------------------------------------------------------

/** List the current user's active timers (running or paused), oldest first. */
export const listActiveTimers = query({
  args: {},
  handler: async (ctx) => {
    const user = await getCurrentUserOrThrow(ctx);

    const running = await ctx.db
      .query("timeEntries")
      .withIndex("by_user_status", (q) => q.eq("userId", user._id).eq("status", "running"))
      .collect();

    const paused = await ctx.db
      .query("timeEntries")
      .withIndex("by_user_status", (q) => q.eq("userId", user._id).eq("status", "paused"))
      .collect();

    return [...running, ...paused].sort((a, b) => a.startedAt - b.startedAt);
  },
});

/** List entries within a date range (by startedAt). */
export const listByDateRange = query({
  args: {
    startDate: v.number(),
    endDate: v.number(),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);

    return await ctx.db
      .query("timeEntries")
      .withIndex("by_user_started_at", (q) =>
        q
          .eq("userId", user._id)
          .gte("startedAt", args.startDate)
          .lt("startedAt", args.endDate),
      )
      .collect();
  },
});

/** List recent completed entries (most recent first). */
export const listRecent = query({
  args: {
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const max = args.limit ?? 20;

    return await ctx.db
      .query("timeEntries")
      .withIndex("by_user_status", (q) =>
        q.eq("userId", user._id).eq("status", "completed"),
      )
      .order("desc")
      .take(max);
  },
});

/**
 * List entries with optional filters.
 * Supports filtering by folder, label, date range, and status.
 */
export const listWithFilters = query({
  args: {
    folderId: v.optional(v.id("folders")),
    inbox: v.optional(v.boolean()),
    labelId: v.optional(v.id("labels")),
    startDate: v.optional(v.number()),
    endDate: v.optional(v.number()),
    status: v.optional(
      v.union(v.literal("running"), v.literal("paused"), v.literal("completed")),
    ),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const max = args.limit ?? 50;

    let entries: Doc<"timeEntries">[];

    // Use the most selective index available
    if (args.folderId !== undefined) {
      entries = await ctx.db
        .query("timeEntries")
        .withIndex("by_user_folder", (q) =>
          q.eq("userId", user._id).eq("folderId", args.folderId),
        )
        .collect();
    } else if (args.inbox) {
      entries = await ctx.db
        .query("timeEntries")
        .withIndex("by_user_folder", (q) =>
          q.eq("userId", user._id).eq("folderId", undefined),
        )
        .collect();
    } else if (args.status !== undefined) {
      entries = await ctx.db
        .query("timeEntries")
        .withIndex("by_user_status", (q) =>
          q.eq("userId", user._id).eq("status", args.status!),
        )
        .collect();
    } else {
      entries = await ctx.db
        .query("timeEntries")
        .withIndex("by_user_started_at", (q) => q.eq("userId", user._id))
        .order("desc")
        .collect();
    }

    // Apply remaining filters in memory
    let filtered = entries;

    if (args.startDate !== undefined) {
      filtered = filtered.filter((e) => e.startedAt >= args.startDate!);
    }
    if (args.endDate !== undefined) {
      filtered = filtered.filter((e) => e.startedAt <= args.endDate!);
    }
    if (args.status !== undefined && args.folderId !== undefined) {
      filtered = filtered.filter((e) => e.status === args.status);
    }
    if (args.labelId !== undefined) {
      filtered = filtered.filter((e) => e.manualLabelIds.includes(args.labelId!));
    }

    // Sort by startedAt descending and apply limit
    filtered.sort((a, b) => b.startedAt - a.startedAt);

    return filtered.slice(0, max);
  },
});

/**
 * Paginate entries with optional filters. The cursor follows the most useful
 * available index; filters that are not represented by that index are applied
 * to each page before it is returned.
 */
export const paginateWithFilters = query({
  args: {
    paginationOpts: paginationOptsValidator,
    folderId: v.optional(v.id("folders")),
    inbox: v.optional(v.boolean()),
    labelId: v.optional(v.id("labels")),
    searchText: v.optional(v.string()),
    startDate: v.optional(v.number()),
    endDate: v.optional(v.number()),
    status: v.optional(
      v.union(v.literal("running"), v.literal("paused"), v.literal("completed")),
    ),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);

    const result =
      args.folderId !== undefined
        ? await ctx.db
            .query("timeEntries")
            .withIndex("by_user_folder", (q) =>
              q.eq("userId", user._id).eq("folderId", args.folderId),
            )
            .order("desc")
            .paginate(args.paginationOpts)
        : args.inbox
          ? await ctx.db
              .query("timeEntries")
              .withIndex("by_user_folder", (q) =>
                q.eq("userId", user._id).eq("folderId", undefined),
              )
              .order("desc")
              .paginate(args.paginationOpts)
          : args.status !== undefined
            ? await ctx.db
                .query("timeEntries")
                .withIndex("by_user_status", (q) =>
                  q.eq("userId", user._id).eq("status", args.status!),
                )
                .order("desc")
                .paginate(args.paginationOpts)
            : await ctx.db
                .query("timeEntries")
                .withIndex("by_user_started_at", (q) => q.eq("userId", user._id))
                .order("desc")
                .paginate(args.paginationOpts);

    let page = result.page;
    if (args.startDate !== undefined) {
      page = page.filter((entry) => entry.startedAt >= args.startDate!);
    }
    if (args.endDate !== undefined) {
      page = page.filter((entry) => entry.startedAt <= args.endDate!);
    }
    if (args.status !== undefined && (args.folderId !== undefined || args.inbox)) {
      page = page.filter((entry) => entry.status === args.status);
    }
    if (args.labelId !== undefined) {
      const folders = await ctx.db
        .query("folders")
        .withIndex("by_user", (q) => q.eq("userId", user._id))
        .collect();
      const foldersById = new Map(folders.map((folder) => [folder._id, folder]));

      page = page.filter((entry) => {
        if (entry.manualLabelIds.includes(args.labelId!)) return true;

        let folder = entry.folderId
          ? foldersById.get(entry.folderId)
          : undefined;
        const visited = new Set<string>();
        while (folder && !visited.has(folder._id)) {
          visited.add(folder._id);
          if (folder.defaultLabelIds.includes(args.labelId!)) return true;
          folder = folder.parentFolderId
            ? foldersById.get(folder.parentFolderId)
            : undefined;
        }
        return false;
      });
    }
    if (args.searchText?.trim()) {
      const searchText = args.searchText.trim().toLocaleLowerCase();
      page = page.filter((entry) =>
        `${entry.title} ${entry.notes ?? ""}`
          .toLocaleLowerCase()
          .includes(searchText),
      );
    }

    page.sort((a, b) => b.startedAt - a.startedAt);
    return { ...result, page };
  },
});

// ---------------------------------------------------------------------------
// Mutations — Timer lifecycle
// ---------------------------------------------------------------------------

/**
 * Start a new timer.
 * - Multiple timers may run concurrently
 * - Creates the first segment
 * - Defaults to Inbox if no folder is selected
 */
export const startTimer = mutation({
  args: {
    title: v.optional(v.string()),
    notes: v.optional(v.string()),
    folderId: v.optional(v.id("folders")),
    manualLabelIds: v.optional(v.array(v.id("labels"))),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);

    if (args.folderId) {
      const folder = await ctx.db.get(args.folderId);
      if (!folder || folder.userId !== user._id) {
        throw new Error("Folder not found");
      }
    }

    const now = wholeSecondNow();

    return await ctx.db.insert("timeEntries", {
      userId: user._id,
      folderId: args.folderId,
      title: args.title ?? "",
      notes: args.notes,
      manualLabelIds: args.manualLabelIds ?? [],
      status: "running",
      segments: [{ startTime: now }],
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    });
  },
});

/** Edit a running or paused timer without changing its lifecycle state. */
export const editActiveTimer = mutation({
  args: {
    entryId: v.id("timeEntries"),
    title: v.optional(v.string()),
    notes: v.optional(v.string()),
    folderId: v.optional(v.id("folders")),
    clearFolder: v.optional(v.boolean()),
    manualLabelIds: v.optional(v.array(v.id("labels"))),
    startTime: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }
    if (entry.status === "completed") {
      throw new Error("Only an active timer can be edited here");
    }
    if (args.folderId) {
      const folder = await ctx.db.get(args.folderId);
      if (!folder || folder.userId !== user._id) {
        throw new Error("Folder not found");
      }
    }

    const updates: Partial<Doc<"timeEntries">> = {
      updatedAt: wholeSecondNow(),
    };

    if (args.title !== undefined) updates.title = args.title;
    if (args.notes !== undefined) updates.notes = args.notes;
    if (args.manualLabelIds !== undefined) {
      updates.manualLabelIds = args.manualLabelIds;
    }
    if (args.folderId !== undefined) {
      updates.folderId = args.folderId;
    } else if (args.clearFolder) {
      updates.folderId = undefined;
    }
    if (args.startTime !== undefined) {
      const segments = retimeActiveTimerSegments(
        entry.segments,
        args.startTime,
        Date.now(),
      );
      updates.segments = segments;
      updates.startedAt = segments[0].startTime;
    }

    await ctx.db.patch(args.entryId, updates);
    return args.entryId;
  },
});

/** Pause the current running timer. */
export const pauseTimer = mutation({
  args: {
    entryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    if (entry.status !== "running") {
      throw new Error(`Cannot pause a timer that is ${entry.status}`);
    }

    const now = wholeSecondNow();

    const segments = entry.segments.map((seg, i) => {
      if (i === entry.segments.length - 1 && seg.endTime === undefined) {
        return { ...seg, endTime: now };
      }
      return seg;
    });

    await ctx.db.patch(args.entryId, {
      status: "paused",
      segments,
      updatedAt: now,
    });

    return args.entryId;
  },
});

/** Resume a paused timer. */
export const resumeTimer = mutation({
  args: {
    entryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    if (entry.status !== "paused") {
      throw new Error(`Cannot resume a timer that is ${entry.status}`);
    }

    const now = wholeSecondNow();

    await ctx.db.patch(args.entryId, {
      status: "running",
      segments: [...entry.segments, { startTime: now }],
      updatedAt: now,
    });

    return args.entryId;
  },
});

/** Stop a running or paused timer. Computes and stores durationSeconds. */
export const stopTimer = mutation({
  args: {
    entryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    if (entry.status === "completed") {
      throw new Error("Timer is already stopped");
    }

    const now = wholeSecondNow();

    const segments = entry.segments.map((seg, i) => {
      if (i === entry.segments.length - 1 && seg.endTime === undefined) {
        return { ...seg, endTime: now };
      }
      return seg;
    });

    const durationSeconds = computeDurationSeconds(segments);

    await ctx.db.patch(args.entryId, {
      status: "completed",
      segments,
      endedAt: now,
      durationSeconds,
      updatedAt: now,
    });

    return args.entryId;
  },
});

/** Discard an active timer (running or paused). Deletes the entry entirely. */
export const discardTimer = mutation({
  args: {
    entryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    if (entry.status === "completed") {
      throw new Error("Cannot discard a completed timer. Use delete instead.");
    }

    await ctx.db.delete(args.entryId);

    return args.entryId;
  },
});

/** Continue a previous entry as a new running timer. */
export const continueEntry = mutation({
  args: {
    sourceEntryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);

    const source = await ctx.db.get(args.sourceEntryId);

    if (!source || source.userId !== user._id) {
      throw new Error("Source entry not found");
    }

    const now = wholeSecondNow();

    return await ctx.db.insert("timeEntries", {
      userId: user._id,
      folderId: source.folderId,
      title: source.title,
      notes: source.notes,
      manualLabelIds: source.manualLabelIds,
      status: "running",
      segments: [{ startTime: now }],
      startedAt: now,
      createdAt: now,
      updatedAt: now,
    });
  },
});

// ---------------------------------------------------------------------------
// Mutations — Manual entries & CRUD
// ---------------------------------------------------------------------------

/**
 * Create a manual (completed) time entry.
 * The caller provides explicit start and end times.
 * Duration is computed automatically from the single segment.
 */
export const createManualEntry = mutation({
  args: {
    title: v.string(),
    notes: v.optional(v.string()),
    folderId: v.optional(v.id("folders")),
    manualLabelIds: v.optional(v.array(v.id("labels"))),
    startTime: v.number(),
    endTime: v.number(),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);

    if (args.endTime <= args.startTime) {
      throw new Error("End time must be after start time");
    }

    // Validate folder
    if (args.folderId) {
      const folder = await ctx.db.get(args.folderId);
      if (!folder || folder.userId !== user._id) {
        throw new Error("Folder not found");
      }
    }

    const segments = [{ startTime: args.startTime, endTime: args.endTime }];
    const durationSeconds = computeDurationSeconds(segments);
    const now = Date.now();

    return await ctx.db.insert("timeEntries", {
      userId: user._id,
      folderId: args.folderId,
      title: args.title,
      notes: args.notes,
      manualLabelIds: args.manualLabelIds ?? [],
      status: "completed",
      segments,
      startedAt: args.startTime,
      endedAt: args.endTime,
      durationSeconds,
      createdAt: now,
      updatedAt: now,
    });
  },
});

/**
 * Edit an existing completed entry.
 * Allows updating title, notes, folder, labels, and time range.
 * Recomputes durationSeconds if times change.
 */
export const editEntry = mutation({
  args: {
    entryId: v.id("timeEntries"),
    title: v.optional(v.string()),
    notes: v.optional(v.string()),
    folderId: v.optional(v.id("folders")),
    clearFolder: v.optional(v.boolean()),
    manualLabelIds: v.optional(v.array(v.id("labels"))),
    startTime: v.optional(v.number()),
    endTime: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    if (entry.status !== "completed") {
      throw new Error("Can only edit completed entries. Stop the timer first.");
    }

    // Validate folder if changing
    if (args.folderId) {
      const folder = await ctx.db.get(args.folderId);
      if (!folder || folder.userId !== user._id) {
        throw new Error("Folder not found");
      }
    }

    const updates: Record<string, unknown> = {
      updatedAt: Date.now(),
    };

    if (args.title !== undefined) updates.title = args.title;
    if (args.notes !== undefined) updates.notes = args.notes;
    if (args.manualLabelIds !== undefined) updates.manualLabelIds = args.manualLabelIds;

    // Handle folder: explicit folderId sets it, clearFolder moves to Inbox
    if (args.folderId !== undefined) {
      updates.folderId = args.folderId;
    } else if (args.clearFolder) {
      updates.folderId = undefined;
    }

    // Handle time changes — recompute segments and duration
    const newStart = args.startTime ?? entry.startedAt;
    const newEnd = args.endTime ?? entry.endedAt;

    if (args.startTime !== undefined || args.endTime !== undefined) {
      if (!newEnd || newEnd <= newStart) {
        throw new Error("End time must be after start time");
      }

      const segments = [{ startTime: newStart, endTime: newEnd }];
      updates.segments = segments;
      updates.startedAt = newStart;
      updates.endedAt = newEnd;
      updates.durationSeconds = computeDurationSeconds(segments);
    }

    await ctx.db.patch(args.entryId, updates);

    return args.entryId;
  },
});

/** Delete an entry. */
export const deleteEntry = mutation({
  args: {
    entryId: v.id("timeEntries"),
  },
  handler: async (ctx, args) => {
    const user = await getCurrentUserOrThrow(ctx);
    const entry = await ctx.db.get(args.entryId);

    if (!entry || entry.userId !== user._id) {
      throw new Error("Time entry not found");
    }

    await ctx.db.delete(args.entryId);

    return args.entryId;
  },
});
