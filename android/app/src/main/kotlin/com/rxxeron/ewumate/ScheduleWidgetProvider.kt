package com.rxxeron.ewumate

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import org.json.JSONArray

class ScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val jsonStr = widgetData.getString("schedule_json", null)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.schedule_widget)
            
            if (jsonStr != null) {
                try {
                    val data = JSONObject(jsonStr)
                    val status = data.optString("status", "chill")
                    val reason = data.optString("reason", "")
                    val displayDate = data.optString("displayDate", "")
                    
                    views.setTextViewText(R.id.widget_date, displayDate)
                    
                    if (status == "holiday" || status == "chill") {
                        views.setViewVisibility(R.id.empty_state_view, View.VISIBLE)
                        views.setViewVisibility(R.id.schedule_list_view, View.GONE)
                        
                        val emptyText = if (status == "holiday") {
                            "Holiday\n$reason"
                        } else {
                            if (reason.isNotEmpty()) reason else "Chill Mode\nNo classes scheduled."
                        }
                        views.setTextViewText(R.id.empty_state_text, emptyText)
                    } else {
                        views.setViewVisibility(R.id.empty_state_view, View.GONE)
                        views.setViewVisibility(R.id.schedule_list_view, View.VISIBLE)
                        
                        val schedule = data.optJSONArray("schedule") ?: JSONArray()
                        
                        // Reset all slots to GONE initially
                        views.setViewVisibility(R.id.slot_1, View.GONE)
                        views.setViewVisibility(R.id.slot_2, View.GONE)
                        views.setViewVisibility(R.id.slot_3, View.GONE)
                        views.setViewVisibility(R.id.slot_4, View.GONE)
                        
                        val maxSlots = 4
                        val itemsToShow = if (schedule.length() > maxSlots) maxSlots else schedule.length()
                        
                        for (i in 0 until itemsToShow) {
                            val item = schedule.getJSONObject(i)
                            val courseCode = item.optString("courseCode", "")
                            val startTime = item.optString("startTime", "")
                            val room = item.optString("room", "")
                            val isCancelled = item.optBoolean("isCancelled", false)
                            val isMakeup = item.optBoolean("isMakeup", false)
                            
                            val slotId = when(i) {
                                0 -> R.id.slot_1
                                1 -> R.id.slot_2
                                2 -> R.id.slot_3
                                3 -> R.id.slot_4
                                else -> R.id.slot_1
                            }
                            
                            val codeId = when(i) {
                                0 -> R.id.slot_1_code
                                1 -> R.id.slot_2_code
                                2 -> R.id.slot_3_code
                                3 -> R.id.slot_4_code
                                else -> R.id.slot_1_code
                            }
                            
                            val timeId = when(i) {
                                0 -> R.id.slot_1_time
                                1 -> R.id.slot_2_time
                                2 -> R.id.slot_3_time
                                3 -> R.id.slot_4_time
                                else -> R.id.slot_1_time
                            }
                            
                            val roomId = when(i) {
                                0 -> R.id.slot_1_room
                                1 -> R.id.slot_2_room
                                2 -> R.id.slot_3_room
                                3 -> R.id.slot_4_room
                                else -> R.id.slot_1_room
                            }
                            
                            views.setViewVisibility(slotId, View.VISIBLE)
                            
                            var displayCode = courseCode
                            if (isCancelled) {
                                displayCode += " (Cancelled)"
                                views.setTextColor(codeId, Color.parseColor("#EF4444"))
                            } else if (isMakeup) {
                                displayCode += " (Makeup)"
                                views.setTextColor(codeId, Color.parseColor("#A855F7"))
                            } else {
                                views.setTextColor(codeId, Color.parseColor("#22D3EE"))
                            }
                            
                            views.setTextViewText(codeId, displayCode)
                            views.setTextViewText(timeId, startTime)
                            views.setTextViewText(roomId, room)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    views.setViewVisibility(R.id.empty_state_view, View.VISIBLE)
                    views.setTextViewText(R.id.empty_state_text, "Error loading schedule")
                }
            } else {
                views.setViewVisibility(R.id.empty_state_view, View.VISIBLE)
                views.setTextViewText(R.id.empty_state_text, "Open app to load schedule")
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
