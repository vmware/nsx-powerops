import { ComponentFixture, TestBed } from '@angular/core/testing';

import { LoadbalcingComponent } from './loadbalcing.component';

describe('LoadbalcingComponent', () => {
  let component: LoadbalcingComponent;
  let fixture: ComponentFixture<LoadbalcingComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ LoadbalcingComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(LoadbalcingComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
