import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";
export default defineSchema({
      agents: defineTable({
                agentId: v.string(),
                name: v.string(),
                emoji: v.string(),
                role: v.string(),
                model: v.string(),
                status: v.string(),
                lastHeartbeat: v.number(),
      }).index("by_agentId", ["agentId"]),
      tasks: defineTable({
                title: v.string(),
                description: v.optional(v.string()),
                status: v.string(),
                priority: v.string(),
                assignedTo: v.optional(v.string()),
                createdBy: v.string(),
                dueDate: v.optional(v.number()),
      }).index("by_status", ["status"]).index("by_assignedTo", ["assignedTo"]),
      comments: defineTable({
                taskId: v.id("tasks"),
                agentId: v.string(),
                content: v.string(),
                mentions: v.optional(v.array(v.string())),
      }),
      documents: defineTable({
                title: v.string(),
                content: v.string(),
                category: v.string(),
                createdBy: v.string(),
      }),
      activities: defineTable({
                agentId: v.string(),
                action: v.string(),
                targetType: v.optional(v.string()),
                targetId: v.optional(v.string()),
                details: v.optional(v.string()),
      }).index("by_agent", ["agentId"]),
      notifications: defineTable({
                agentId: v.string(),
                type: v.string(),
                sourceAgent: v.string(),
                message: v.string(),
                read: v.boolean(),
                taskId: v.optional(v.id("tasks")),
      }).index("by_agent_unread", ["agentId", "read"]),
});
