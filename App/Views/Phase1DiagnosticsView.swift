import SwiftUI
import UIKit

struct Phase1DiagnosticsView: View {
    @State private var diagnostics: GemmaEdgeDiagnostics = GemmaEdgeBridge.probeSystem()
    @State private var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @State private var copiedFeedback = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        headerCard
                        metalAndBackendCard
                        memoryBudgetCard
                        systemInfoCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("GemmaEdge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppTheme.accentPrimary)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in
                thermalState = ProcessInfo.processInfo.thermalState
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Phase 1 Engine Probe", systemImage: "cpu.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(thermalBadgeText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(thermalBadgeColor.opacity(0.18), in: Capsule())
                    .foregroundStyle(thermalBadgeColor)
            }

            Text("Target: Gemma 4 26B A4B (3.8B active / 128 experts, top-8) via Metal + Flash-MoE Streaming")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(16)
        .background(AppTheme.backgroundElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.borderSubtle, lineWidth: 1))
    }

    private var metalAndBackendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("METAL & LLAMA.CPP V1.0.0 BACKEND")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            metricRow("Metal Device", value: diagnostics.metalDeviceName, ok: diagnostics.metalSupported)
            metricRow("Unified Memory", value: diagnostics.hasUnifiedMemory ? "Yes (UMA)" : "No", ok: diagnostics.hasUnifiedMemory)
            metricRow("llama GPU Offload", value: diagnostics.llamaGpuOffloadSupported ? "Enabled" : "Disabled", ok: diagnostics.llamaGpuOffloadSupported)
            metricRow("llama mmap Support", value: diagnostics.llamaMmapSupported ? "Available" : "No", ok: true)
            metricRow("Backend Devices", value: "\(diagnostics.llamaMaxDevices)", ok: diagnostics.llamaMaxDevices > 0)
        }
        .padding(16)
        .background(AppTheme.backgroundElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.borderSubtle, lineWidth: 1))
    }

    private var memoryBudgetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("IOS JETSAM & EXPERT CACHE BUDGET")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            metricRow("Device RAM", value: formatMB(diagnostics.physicalMemoryMB), ok: true)
            metricRow("App Footprint", value: formatMB(diagnostics.physFootprintMB), ok: true)
            metricRow("Available Headroom", value: formatMB(diagnostics.procAvailableMemoryMB), ok: diagnostics.procAvailableMemoryMB > 2000)
            metricRow("Jetsam Ceiling (Est.)", value: formatMB(diagnostics.estimatedJetsamCeilingMB), ok: diagnostics.estimatedJetsamCeilingMB > 3000)
            metricRow("Metal Recommended Max", value: formatMB(diagnostics.recommendedWorkingSetMB), ok: true)
            Divider().overlay(AppTheme.borderSubtle)
            HStack {
                Text("Auto Hot-Expert Cache Budget")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(formatMB(diagnostics.suggestedHotExpertBudgetMB))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(AppTheme.accentPrimary)
            }
        }
        .padding(16)
        .background(AppTheme.backgroundElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.borderSubtle, lineWidth: 1))
    }

    private var systemInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LLAMA SYSTEM INFO")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = fullReportString
                    copiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copiedFeedback = false
                    }
                } label: {
                    Label(copiedFeedback ? "Copied" : "Copy Report", systemImage: copiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accentPrimary)
                }
            }

            Text(diagnostics.llamaSystemInfo.isEmpty ? "No system info returned" : diagnostics.llamaSystemInfo)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(AppTheme.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(16)
        .background(AppTheme.backgroundElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.borderSubtle, lineWidth: 1))
    }

    private func metricRow(_ label: String, value: String, ok: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(ok ? AppTheme.textPrimary : AppTheme.statusRed)
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024.0 {
            return String(format: "%.2f GiB (%.0f MiB)", mb / 1024.0, mb)
        }
        return String(format: "%.0f MiB", mb)
    }

    private var thermalBadgeText: String {
        switch thermalState {
        case .nominal: return "Thermal: Nominal"
        case .fair: return "Thermal: Fair"
        case .serious: return "Thermal: Serious"
        case .critical: return "Thermal: Critical"
        @unknown default: return "Thermal: Unknown"
        }
    }

    private var thermalBadgeColor: Color {
        switch thermalState {
        case .nominal: return AppTheme.statusGreen
        case .fair: return AppTheme.accentPrimary
        case .serious: return AppTheme.statusAmber
        case .critical: return AppTheme.statusRed
        @unknown default: return AppTheme.textSecondary
        }
    }

    private var fullReportString: String {
        """
        Metal: \(diagnostics.metalDeviceName) (Supported: \(diagnostics.metalSupported), UMA: \(diagnostics.hasUnifiedMemory))
        llama GPU Offload: \(diagnostics.llamaGpuOffloadSupported) | Devices: \(diagnostics.llamaMaxDevices)
        Device RAM: \(formatMB(diagnostics.physicalMemoryMB))
        Footprint: \(formatMB(diagnostics.physFootprintMB))
        Available: \(formatMB(diagnostics.procAvailableMemoryMB))
        Jetsam Ceiling Est: \(formatMB(diagnostics.estimatedJetsamCeilingMB))
        Suggested Expert Budget: \(formatMB(diagnostics.suggestedHotExpertBudgetMB))
        System Info: \(diagnostics.llamaSystemInfo)
        """
    }

    private func refresh() {
        diagnostics = GemmaEdgeBridge.probeSystem()
        thermalState = ProcessInfo.processInfo.thermalState
    }
}
