import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NsxSegmentsComponent } from './nsx-segments.component';

describe('NsxSegmentsComponent', () => {
  let component: NsxSegmentsComponent;
  let fixture: ComponentFixture<NsxSegmentsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NsxSegmentsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NsxSegmentsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
