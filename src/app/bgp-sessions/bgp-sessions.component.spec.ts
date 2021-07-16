import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BgpSessionsComponent } from './bgp-sessions.component';

describe('BgpSessionsComponent', () => {
  let component: BgpSessionsComponent;
  let fixture: ComponentFixture<BgpSessionsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ BgpSessionsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(BgpSessionsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
