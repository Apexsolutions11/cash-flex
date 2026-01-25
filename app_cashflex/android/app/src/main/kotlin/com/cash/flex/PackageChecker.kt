package com.cash.flex

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log

object PackageChecker {
    private const val TAG = "PackageChecker"
    
    fun isPackageInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
    
    fun hasAnyPackageInstalled(context: Context, packageNames: List<String>): Boolean {
        return packageNames.any { isPackageInstalled(context, it) }
    }
    
    fun getInstalledPackages(context: Context, packageNames: List<String>): List<String> {
        val installedPackages = mutableListOf<String>()
        for (packageName in packageNames) {
            if (isPackageInstalled(context, packageName)) {
                installedPackages.add(packageName)
            }
        }
        if (installedPackages.isNotEmpty()) {
            Log.d(TAG, "Found installed packages: ${installedPackages.joinToString(", ")}")
        }
        return installedPackages
    }
}

