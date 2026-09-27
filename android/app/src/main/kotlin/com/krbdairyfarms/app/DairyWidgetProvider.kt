package com.krbdairyfarms.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

// ========================
// MAIN DASHBOARD WIDGET
// ========================
class DairyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            val widgetData = HomeWidgetPlugin.getData(context)

            views.setTextViewText(R.id.tv_milk, "${widgetData.getString("today_milk", "--")}L")
            views.setTextViewText(R.id.tv_cows, widgetData.getString("total_cows", "--"))
            views.setTextViewText(R.id.tv_profit, "₹${widgetData.getString("net_profit", "--")}")
            views.setTextViewText(R.id.tv_date, SimpleDateFormat("dd MMM", Locale.getDefault()).format(Date()))

            // Open App button → dashboard
            val openIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.btn_open_app, openIntent)

            // Add Milk button → deep link
            val milkIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("diaryapp://widget/add_milk"))
            views.setOnClickPendingIntent(R.id.btn_add_milk, milkIntent)

            // Add Expense button → deep link
            val expenseIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("diaryapp://widget/add_expense"))
            views.setOnClickPendingIntent(R.id.btn_add_expense, expenseIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ========================
// MILK STAT WIDGET
// ========================
class MilkWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_milk)
            val widgetData = HomeWidgetPlugin.getData(context)
            views.setTextViewText(R.id.tv_milk_value, "${widgetData.getString("today_milk", "--")}L")
            views.setTextViewText(R.id.tv_milk_date, SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date()))
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_milk_root, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ========================
// COWS STAT WIDGET
// ========================
class CowsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_cows)
            val widgetData = HomeWidgetPlugin.getData(context)
            views.setTextViewText(R.id.tv_cows_value, widgetData.getString("total_cows", "--"))
            views.setTextViewText(R.id.tv_cows_date, SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date()))
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_cows_root, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ========================
// PROFIT STAT WIDGET
// ========================
class ProfitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_profit)
            val widgetData = HomeWidgetPlugin.getData(context)
            views.setTextViewText(R.id.tv_profit_value, "₹${widgetData.getString("net_profit", "--")}")
            views.setTextViewText(R.id.tv_profit_date, SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(Date()))
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_profit_root, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

// ========================
// ACTION WIDGETS
// ========================
class AddMilkWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_add_milk)
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("diaryapp://widget/add_milk"))
            views.setOnClickPendingIntent(R.id.btn_action, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class AddExpenseWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_add_expense)
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("diaryapp://widget/add_expense"))
            views.setOnClickPendingIntent(R.id.btn_action, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class AddPaymentWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_add_payment)
            val intent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("diaryapp://widget/add_payment"))
            views.setOnClickPendingIntent(R.id.btn_action, intent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
