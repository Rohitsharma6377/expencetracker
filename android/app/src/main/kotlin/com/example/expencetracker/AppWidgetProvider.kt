package com.example.expencetracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val total = widgetData.getFloat("today_total", 0.0f)
                setTextViewText(R.id.today_total, "₹${String.format("%.2f", total)}")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
