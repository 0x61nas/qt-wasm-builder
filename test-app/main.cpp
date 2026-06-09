#include <QApplication>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWidget>
#include <QTextEdit>

#if defined(__EMSCRIPTEN__)
#include <QtPlugin>
extern const QStaticPlugin qt_static_plugin_QWasmIntegrationPlugin();
static void initWasmPlugin() {
    qRegisterStaticPluginFunction(qt_static_plugin_QWasmIntegrationPlugin());
}
#endif

int main(int argc, char *argv[]) {
#if defined(__EMSCRIPTEN__)
    initWasmPlugin();
#endif
    QApplication app(argc, argv);

    auto *window = new QWidget;
    auto *layout = new QVBoxLayout(window);

    auto *btn = new QPushButton("Hello from Qt WASM on Alpine!");
    btn->setStyleSheet(
        "QPushButton { font-size: 18px; padding: 12px 24px;"
        " background-color: #4a9eff; color: white; border-radius: 8px; }"
        "QPushButton:hover { background-color: #6ab4ff; }"
    );

    auto *info = new QTextEdit;
    info->setReadOnly(true);
    info->setPlainText(
        "Qt Version: " QT_VERSION_STR "\n"
        "Built with: Emscripten\n"
        "Platform: WebAssembly\n\n"
        "This app demonstrates a working Qt WASM\n"
        "builder image based on Alpine Linux."
    );
    info->setMaximumHeight(120);

    layout->addWidget(btn);
    layout->addWidget(info);
    layout->addStretch();

    window->setWindowTitle("Qt WASM Test");
    window->resize(500, 350);
    window->show();

    QObject::connect(btn, &QPushButton::clicked, [&]() {
        btn->setText("Clicked! ✓");
    });

    return app.exec();
}
