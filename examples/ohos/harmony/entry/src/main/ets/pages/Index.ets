import native from '@nanaloveyuki/runtimebinding';

@Entry
@Component
struct Index {
  @State status: string = '';

  aboutToAppear(): void {
    this.runLogging();
  }

  private runLogging(): void {
    try {
      this.status = native.run_logging();
    } catch (error) {
      this.status = `Logging failed: ${JSON.stringify(error)}`;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('Runtime Bindings').fontSize(22)
      Text(this.status).fontSize(18)
      Button('Write logs again').onClick(() => this.runLogging())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
