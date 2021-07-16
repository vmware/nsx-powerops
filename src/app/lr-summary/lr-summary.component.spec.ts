import { ComponentFixture, TestBed } from '@angular/core/testing';

import { LrSummaryComponent } from './lr-summary.component';

describe('LrSummaryComponent', () => {
  let component: LrSummaryComponent;
  let fixture: ComponentFixture<LrSummaryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ LrSummaryComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(LrSummaryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
