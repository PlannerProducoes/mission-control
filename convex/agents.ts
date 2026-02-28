import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
export const heartbeat = mutation({
      args: {
                agentId: v.string(),
                status: v.string(),
                name: v.optional(v.string()),
                emoji: v.optional(v.string()),
                role: v.optional(v.string()),
                model: v.optional(v.string()),
      },
      handler: async (ctx, args) => {
                const existing = await ctx.db.query("agents").withIndex("by_agentId", (q) => q.eq("agentId", args.agentId)).unique();
                const timestamp = Date.now();
                if (existing) {
                              await ctx.db.patch(existing._id, {
                                                status: args.status,
                                                lastHeartbeat: timestamp,
                                                ...(args.name && { name: args.name }),
                                                ...(args.emoji && { emoji: args.emoji }),
                                                ...(args.role && { role: args.role }),
                                                ...(args.model && { model: args.model }),
                              });
                } else {
                              await ctx.db.insert("agents", {
                                                agentId: args.agentId,
                                                name: args.name ?? args.agentId,
                                                emoji: args.emoji ?? "Robot",
                                                role: args.role ?? "Agent",
                                                model: args.model ?? "default",
                                                status: args.status,
                                                lastHeartbeat: timestamp,
                              });
                }
                const notifications = await ctx.db.query("notifications").withIndex("by_agent_unread", (q) => q.eq("agentId", args.agentId).eq("read", false)).collect();
                const tasks = await ctx.db.query("tasks").withIndex("by_assignedTo", (q) => q.eq("assignedTo", args.agentId)).collect();
                return { notifications, tasks };
      },
});
export const list = query({
      args: {},
      handler: async (ctx) => { return await ctx.db.query("agents").collect(); },
});
