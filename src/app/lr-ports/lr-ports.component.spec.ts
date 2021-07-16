import { ComponentFixture, TestBed } from '@angular/core/testing';

import { LrPortsComponent } from './lr-ports.component';

describe('LrPortsComponent', () => {
  let component: LrPortsComponent;
  let fixture: ComponentFixture<LrPortsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ LrPortsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(LrPortsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
