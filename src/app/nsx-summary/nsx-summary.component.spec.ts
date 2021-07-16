import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NsxSummaryComponent } from './nsx-summary.component';

describe('NsxSummaryComponent', () => {
  let component: NsxSummaryComponent;
  let fixture: ComponentFixture<NsxSummaryComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NsxSummaryComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NsxSummaryComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
