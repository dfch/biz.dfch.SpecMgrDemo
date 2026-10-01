import { Component } from '@angular/core';
import { PipelineDagComponent } from './pipeline-dag.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [PipelineDagComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  title = 'angular-pipeline-viz';
}
