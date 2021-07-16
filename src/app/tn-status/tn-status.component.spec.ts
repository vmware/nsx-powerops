import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TnStatusComponent } from './tn-status.component';

describe('TnStatusComponent', () => {
  let component: TnStatusComponent;
  let fixture: ComponentFixture<TnStatusComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ TnStatusComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TnStatusComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
