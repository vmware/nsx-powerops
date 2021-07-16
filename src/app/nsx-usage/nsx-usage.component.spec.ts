import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NsxUsageComponent } from './nsx-usage.component';

describe('NsxUsageComponent', () => {
  let component: NsxUsageComponent;
  let fixture: ComponentFixture<NsxUsageComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NsxUsageComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NsxUsageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
