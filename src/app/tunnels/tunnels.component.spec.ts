import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TunnelsComponent } from './tunnels.component';

describe('TunnelsComponent', () => {
  let component: TunnelsComponent;
  let fixture: ComponentFixture<TunnelsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ TunnelsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(TunnelsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
