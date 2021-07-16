import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TransportZonesComponent } from './transport-zones.component';

describe('TransportZonesComponent', () => {
  let component: TransportZonesComponent;
  let fixture: ComponentFixture<TransportZonesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ TransportZonesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TransportZonesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
