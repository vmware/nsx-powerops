import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TransportnodesComponent } from './transportnodes.component';

describe('TransportnodesComponent', () => {
  let component: TransportnodesComponent;
  let fixture: ComponentFixture<TransportnodesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ TransportnodesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TransportnodesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
