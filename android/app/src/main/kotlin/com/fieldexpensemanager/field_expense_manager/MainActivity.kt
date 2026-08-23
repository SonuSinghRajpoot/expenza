package com.fieldexpensemanager.field_expense_manager

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private val PDF_RENDERER_CHANNEL = "com.fieldexpensemanager/pdf_renderer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PDF_RENDERER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "renderPdfPages" -> {
                        val pdfPath = call.argument<String>("pdfPath")
                        val outputDir = call.argument<String>("outputDir")
                        if (pdfPath == null || outputDir == null) {
                            result.error("INVALID_ARGS", "pdfPath and outputDir must not be null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = File(pdfPath)
                            if (!file.exists()) {
                                result.error("NOT_FOUND", "PDF file does not exist at $pdfPath", null)
                                return@setMethodCallHandler
                            }
                            val imagePaths = renderPdfFile(file, outputDir)
                            result.success(imagePaths)
                        } catch (e: Exception) {
                            result.error("RENDER_ERROR", e.localizedMessage ?: "Unknown error", null)
                        }
                    }
                    "renderPdfData" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val outputDir = call.argument<String>("outputDir")
                        if (bytes == null || outputDir == null) {
                            result.error("INVALID_ARGS", "bytes and outputDir must not be null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val tempFile = File.createTempFile("temp_render_", ".pdf", cacheDir)
                            tempFile.writeBytes(bytes)
                            val imagePaths = renderPdfFile(tempFile, outputDir)
                            tempFile.delete()
                            result.success(imagePaths)
                        } catch (e: Exception) {
                            result.error("RENDER_ERROR", e.localizedMessage ?: "Unknown error", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun renderPdfFile(file: File, outputDirPath: String): List<String> {
        val imagePaths = mutableListOf<String>()
        val targetDir = File(outputDirPath)
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }

        val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val renderer = PdfRenderer(pfd)
        try {
            val pageCount = renderer.pageCount
            for (i in 0 until pageCount) {
                val page = renderer.openPage(i)
                try {
                    val width = page.width * 2
                    val height = page.height * 2
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    bitmap.eraseColor(Color.WHITE)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                    val outFile = File(targetDir, "pdf_page_${UUID.randomUUID()}_${i + 1}.jpg")
                    FileOutputStream(outFile).use { fos ->
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                    }
                    bitmap.recycle()
                    imagePaths.add(outFile.absolutePath)
                } finally {
                    page.close()
                }
            }
        } finally {
            renderer.close()
            pfd.close()
        }
        return imagePaths
    }
}
