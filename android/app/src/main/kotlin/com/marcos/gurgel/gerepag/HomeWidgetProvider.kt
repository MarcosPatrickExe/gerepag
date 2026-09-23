package com.marcos.gurgel.gerepag

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider as HomeWidget

class HomeWidgetProvider : HomeWidget() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.finance_widget_layout).apply {
                val balance = widgetData.getString("widget_balance", "R$ 0,00")
                val xp = widgetData.getString("widget_xp", "Nível 1 • 0 XP")
                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_xp, xp)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
